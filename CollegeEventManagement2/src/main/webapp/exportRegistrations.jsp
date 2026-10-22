
<%@ page contentType="text/csv; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ include file="includes/db.jspf" %>

<%
    // Allow only administrators
    String role = (String) session.getAttribute("role");

    if (!"ADMIN".equalsIgnoreCase(role == null ? "" : role.trim())) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Get event ID
    String eventIdValue = request.getParameter("eventId");
    int eventId;

    try {
        eventId = Integer.parseInt(eventIdValue);

        if (eventId <= 0) {
            throw new NumberFormatException();
        }
    } catch (Exception ex) {
        response.reset();
        response.sendError(400, "A valid eventId is required.");
        return;
    }

    StringWriter csvBuffer = new StringWriter();
    PrintWriter csv = new PrintWriter(csvBuffer);

    // UTF-8 BOM helps Excel display text correctly
    csv.write('\uFEFF');

    csv.println(
        "Event,Registration ID,Student Name,Email,Department," +
        "Section,Roll Number,Year,Mobile,Registration Status"
    );

    String eventName = null;

    try (Connection con = openConnection()) {

        // Get event name
        String eventSql =
            "SELECT event_name FROM events WHERE event_id = ?";

        try (PreparedStatement eventPs =
                 con.prepareStatement(eventSql)) {

            eventPs.setInt(1, eventId);

            try (ResultSet eventRs = eventPs.executeQuery()) {
                if (eventRs.next()) {
                    eventName = eventRs.getString("event_name");
                }
            }
        }

        if (eventName == null) {
            response.reset();
            response.sendError(404, "Event not found.");
            return;
        }

        // Fetch registrations for this event
        String sql =
            "SELECT registration_id, full_name, email, department, " +
            "section, roll_number, year_of_study, mobile, status " +
            "FROM registrations " +
            "WHERE event_id = ? " +
            "ORDER BY department NULLS LAST, " +
            "section NULLS LAST, " +
            "roll_number NULLS LAST, " +
            "full_name NULLS LAST, registration_id";

        try (PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, eventId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    csv.print(csvField(eventName));
                    csv.print(",");

                    csv.print(csvField(
                        rs.getString("registration_id")));
                    csv.print(",");

                    csv.print(csvField(
                        rs.getString("full_name")));
                    csv.print(",");

                    csv.print(csvField(
                        rs.getString("email")));
                    csv.print(",");

                    csv.print(csvField(
                        rs.getString("department")));
                    csv.print(",");

                    csv.print(csvField(
                        rs.getString("section")));
                    csv.print(",");

                    csv.print(csvField(
                        rs.getString("roll_number")));
                    csv.print(",");

                    csv.print(csvField(
                        rs.getString("year_of_study")));
                    csv.print(",");

                    csv.print(csvField(
                        rs.getString("mobile")));
                    csv.print(",");

                    csv.println(csvField(
                        rs.getString("status")));
                }
            }
        }

    } catch (Exception ex) {
        application.log("Error exporting event registrations", ex);

        response.reset();
        response.sendError(
            500,
            "Unable to export registrations. Check the server log."
        );
        return;
    }

    csv.flush();

    String safeFilePart =
        eventName.replaceAll("[^A-Za-z0-9._-]", "_");

    if (safeFilePart.isEmpty()) {
        safeFilePart = "event";
    }

    response.setContentType("text/csv; charset=UTF-8");

    response.setHeader(
        "Content-Disposition",
        "attachment; filename=\"registrations_" +
        eventId + "_" + safeFilePart + ".csv\""
    );

    response.setCharacterEncoding("UTF-8");

    out.clear();
    out.print(csvBuffer.toString());
    out.flush();
%>

<%!
    // Format CSV values safely
    private String csvField(String value) {

        if (value == null) {
            value = "";
        }

        value = value.replace("\r", " ")
                     .replace("\n", " ");

        // Reduce spreadsheet formula-injection risk
        if (!value.isEmpty()) {
            char first = value.charAt(0);

            if (first == '=' || first == '+' ||
                first == '-' || first == '@' ||
                first == '\t') {
                value = "'" + value;
            }
        }

        // Escape double quotes
        value = value.replace("\"", "\"\"");

        return "\"" + value + "\"";
    }
%>
