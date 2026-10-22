
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="includes/db.jspf" %>

<%
    String role = (String) session.getAttribute("role");

    if (!"ADMIN".equalsIgnoreCase(role == null ? "" : role.trim())) {
        response.sendRedirect("login.jsp");
        return;
    }

    String eventIdParam = request.getParameter("eventId");
    int eventId = 0;
    boolean validEventId = false;

    String eventName = "";
    String category = "";
    String eventDate = "";
    String eventTime = "";
    String venue = "";
    String eventStatus = "";

    int totalRegistered = 0;
    String error = null;
    boolean eventFound = false;

    if (eventIdParam != null && !eventIdParam.trim().isEmpty()) {
        try {
            eventId = Integer.parseInt(eventIdParam.trim());
            validEventId = eventId > 0;
        } catch (NumberFormatException e) {
            validEventId = false;
        }
    }

    if (!validEventId) {
        error = "Invalid event ID.";
    } else {
        try (Connection con = openConnection()) {

            String eventSql =
                "SELECT event_name, category, event_date, event_time, venue, status " +
                "FROM events WHERE event_id = ?";

            try (PreparedStatement ps = con.prepareStatement(eventSql)) {
                ps.setInt(1, eventId);

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        eventFound = true;
                        eventName = rs.getString("event_name");
                        category = rs.getString("category");
                        venue = rs.getString("venue");
                        eventTime = rs.getString("event_time");
                        eventStatus = rs.getString("status");

                        java.sql.Date sqlDate = rs.getDate("event_date");

                        if (sqlDate != null) {
                            eventDate = new java.text.SimpleDateFormat("dd MMM yyyy")
                                .format(sqlDate);
                        }
                    } else {
                        error = "The requested event was not found.";
                    }
                }
            }

            if (eventFound) {
                String countSql =
                    "SELECT COUNT(*) FROM registrations WHERE event_id = ?";

                try (PreparedStatement ps = con.prepareStatement(countSql)) {
                    ps.setInt(1, eventId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            totalRegistered = rs.getInt(1);
                        }
                    }
                }
            }

        } catch (Exception e) {
            application.log("Error loading event registrations", e);
            error = "Unable to load registrations. Please check the server log.";
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Event Registrations | CampusEvents</title>
    <link rel="stylesheet" href="assets/style.css">

    <style>
        .registration-container {
            max-width: 1200px;
            margin: 30px auto;
            padding: 20px;
        }

        .registration-card {
            background: #ffffff;
            padding: 24px;
            margin-bottom: 24px;
            border: 1px solid #e5e9f2;
            border-radius: 12px;
            box-shadow: 0 4px 16px rgba(23, 33, 63, 0.05);
        }

        .registration-card h1 {
            color: #17213f;
            margin-top: 0;
        }

        .event-details {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 16px;
        }

        .detail-item {
            padding: 14px;
            background: #f8fafc;
            border-radius: 8px;
            overflow-wrap: anywhere;
        }

        .detail-label {
            display: block;
            color: #64748b;
            font-size: 13px;
            margin-bottom: 6px;
        }

        .detail-value {
            font-weight: 600;
            color: #17213f;
        }

        .registration-count {
            display: inline-block;
            margin-top: 12px;
            padding: 10px 16px;
            background: #e0e7ff;
            color: #3730a3;
            border-radius: 8px;
            font-weight: bold;
        }

        .table-wrapper {
            overflow-x: auto;
        }

        .registration-table {
            width: 100%;
            min-width: 1000px;
            border-collapse: collapse;
        }

        .registration-table th,
        .registration-table td {
            padding: 12px;
            border-bottom: 1px solid #e2e8f0;
            text-align: left;
            vertical-align: top;
        }

        .registration-table th {
            background: #f1f5f9;
            color: #17213f;
            white-space: nowrap;
        }

        .registration-table td {
            overflow-wrap: anywhere;
        }

        .registration-status {
            display: inline-block;
            padding: 5px 9px;
            background: #e8edf7;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }

        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            text-decoration: none;
        }

        .empty-message {
            text-align: center;
            padding: 25px;
            color: #64748b;
        }

        .error-message {
            padding: 14px;
            background: #fee2e2;
            color: #991b1b;
            border-radius: 8px;
        }

        @media (max-width: 700px) {
            .registration-container {
                padding: 12px;
            }

            .registration-card {
                padding: 16px;
            }

            .event-details {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>

<body>

<%@ include file="includes/header.jspf" %>

<main class="registration-container">

    <a class="back-link" href="admin.jsp#manage-events">
        &larr; Back to Admin Dashboard
    </a>

    <% if (error != null) { %>

        <div class="error-message">
            <%= esc(error) %>
        </div>

    <% } else if (eventFound) { %>

        <section class="registration-card">

            <h1><%= esc(eventName) %></h1>

            <p>Event Registration Details</p>

            <div class="event-details">

                <div class="detail-item">
                    <span class="detail-label">Event ID</span>
                    <span class="detail-value"><%= eventId %></span>
                </div>

                <div class="detail-item">
                    <span class="detail-label">Category</span>
                    <span class="detail-value"><%= esc(category) %></span>
                </div>

                <div class="detail-item">
                    <span class="detail-label">Event Date</span>
                    <span class="detail-value">
                        <%= eventDate.isEmpty() ? "Not specified" : esc(eventDate) %>
                    </span>
                </div>

                <div class="detail-item">
                    <span class="detail-label">Event Time</span>
                    <span class="detail-value">
                        <%= eventTime == null || eventTime.trim().isEmpty()
                            ? "Not specified" : esc(eventTime) %>
                    </span>
                </div>

                <div class="detail-item">
                    <span class="detail-label">Venue</span>
                    <span class="detail-value"><%= esc(venue) %></span>
                </div>

                <div class="detail-item">
                    <span class="detail-label">Event Status</span>
                    <span class="detail-value"><%= esc(eventStatus) %></span>
                </div>

            </div>

            <div class="registration-count">
                Total Registered Students: <%= totalRegistered %>
            </div>

        </section>

        <section class="registration-card">

            <h2>Registered Students</h2>

            <div class="table-wrapper">

                <table class="registration-table">

                    <thead>
                        <tr>
                            <th>Registration ID</th>
                            <th>Student Name</th>
                            <th>Email</th>
                            <th>Department</th>
                            <th>Roll Number</th>
                            <th>Section</th>
                            <th>Year of Study</th>
                            <th>Mobile</th>
                            <th>Gender</th>
                            <th>Status</th>
                            <th>Registered At</th>
                        </tr>
                    </thead>

                    <tbody>

                    <%
                        boolean studentsFound = false;

                        String studentSql =
                            "SELECT registration_id, full_name, email, department, " +
                            "roll_number, section, year_of_study, mobile, gender, " +
                            "status, registered_at " +
                            "FROM registrations WHERE event_id = ? " +
                            "ORDER BY registered_at DESC";

                        try (Connection con = openConnection();
                             PreparedStatement ps = con.prepareStatement(studentSql)) {

                            ps.setInt(1, eventId);

                            try (ResultSet rs = ps.executeQuery()) {

                                while (rs.next()) {
                                    studentsFound = true;
                    %>

                        <tr>
                            <td><%= rs.getInt("registration_id") %></td>

                            <td><%= esc(rs.getString("full_name")) %></td>

                            <td><%= esc(rs.getString("email")) %></td>

                            <td><%= esc(rs.getString("department")) %></td>

                            <td><%= esc(rs.getString("roll_number")) %></td>

                            <td><%= esc(rs.getString("section")) %></td>

                            <td><%= esc(rs.getString("year_of_study")) %></td>

                            <td><%= esc(rs.getString("mobile")) %></td>

                            <td><%= esc(rs.getString("gender")) %></td>

                            <td>
                                <span class="registration-status">
                                    <%= esc(rs.getString("status")) %>
                                </span>
                            </td>

                            <td>
                                <%
                                    Timestamp registeredAt =
                                        rs.getTimestamp("registered_at");

                                    out.print(registeredAt == null
                                        ? "—"
                                        : esc(new java.text.SimpleDateFormat(
                                            "dd MMM yyyy, hh:mm a"
                                        ).format(registeredAt)));
                                %>
                            </td>
                        </tr>

                    <%
                                }
                            }

                        } catch (Exception e) {
                            application.log("Error loading student registration list", e);
                    %>

                        <tr>
                            <td colspan="11">
                                Unable to load student details. Check the server log.
                            </td>
                        </tr>

                    <%
                        }

                        if (!studentsFound) {
                    %>

                        <tr>
                            <td colspan="11" class="empty-message">
                                No students have registered for this event yet.
                            </td>
                        </tr>

                    <%
                        }
                    %>

                    </tbody>

                </table>

            </div>

        </section>

    <% } %>

</main>

<footer class="footer">
    College Event Management System
</footer>

</body>
</html>
