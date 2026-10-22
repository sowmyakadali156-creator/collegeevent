
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="includes/db.jspf" %>

<%
    Object sessionUserId = session.getAttribute("userId");
    String role = String.valueOf(session.getAttribute("role"));

    if (sessionUserId == null || !"STUDENT".equalsIgnoreCase(role)) {
        response.sendRedirect("login.jsp");
        return;
    }

    int uid;

    try {
        uid = Integer.parseInt(String.valueOf(sessionUserId));
    } catch (NumberFormatException e) {
        session.invalidate();
        response.sendRedirect("login.jsp");
        return;
    }

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>My Registrations - CampusEvents</title>

    <link rel="stylesheet" href="assets/style.css">

    <style>
        .registrations-container {
            width: 100%;
            max-width: 1250px;
            margin: 35px auto;
            padding: 0 22px;
            box-sizing: border-box;
        }

        .registrations-heading {
            margin-bottom: 25px;
        }

        .registrations-heading h1 {
            color: #172554;
            margin-bottom: 8px;
        }

        .registrations-heading p {
            color: #69758c;
            line-height: 1.6;
        }

        .registrations-card {
            padding: 24px;
            background: #ffffff;
            border: 1px solid #e5e9f2;
            border-radius: 14px;
            box-shadow: 0 5px 18px rgba(23, 33, 63, 0.05);
        }

        .admin-table-wrapper {
            width: 100%;
            overflow-x: auto;
        }

        .admin-table {
            width: 100%;
            min-width: 750px;
            border-collapse: collapse;
        }

        .admin-table th,
        .admin-table td {
            padding: 14px;
            text-align: left;
            border-bottom: 1px solid #e5e9f2;
            vertical-align: middle;
        }

        .admin-table th {
            background: #eef1fa;
            color: #172554;
            white-space: nowrap;
        }

        .admin-table tbody tr:hover {
            background: #f8faff;
        }

        .registration-status {
            display: inline-block;
            padding: 6px 11px;
            border-radius: 20px;
            background: #e0e7ff;
            color: #273c75;
            font-size: 12px;
            font-weight: 700;
        }

        .registrations-empty,
        .registrations-error {
            padding: 18px;
            border-radius: 8px;
            line-height: 1.6;
        }

        .registrations-empty {
            background: #f4f6fb;
            color: #69758c;
        }

        .registrations-error {
            background: #fff0e9;
            color: #a33b18;
        }

        @media (max-width: 600px) {
            .registrations-container {
                padding: 0 12px;
                margin: 22px auto;
            }

            .registrations-card {
                padding: 14px;
            }

            .registrations-heading h1 {
                font-size: 25px;
            }
        }
    </style>
</head>

<body>

<%@ include file="includes/header.jspf" %>

<main class="registrations-container">

    <div class="registrations-heading">
        <h1>My Event Registrations</h1>
        <p>View the events you have registered for and their current status.</p>
    </div>

    <div class="registrations-card">

        <div class="admin-table-wrapper">

            <table class="admin-table">

                <thead>
                    <tr>
                        <th>Event Name</th>
                        <th>Category</th>
                        <th>Date</th>
                        <th>Time</th>
                        <th>Venue</th>
                        <th>Status</th>
                    </tr>
                </thead>

                <tbody>

                <%
                    boolean found = false;

                    try {
                        con = openConnection();

                        String sql =
                            "SELECT e.event_name, e.category, e.event_date, " +
                            "e.event_time, e.venue, r.status " +
                            "FROM registrations r " +
                            "JOIN events e ON r.event_id = e.event_id " +
                            "WHERE r.user_id = ? " +
                            "ORDER BY e.event_date";

                        ps = con.prepareStatement(sql);
                        ps.setInt(1, uid);

                        rs = ps.executeQuery();

                        while (rs.next()) {
                            found = true;

                            String eventName = rs.getString("event_name");
                            String category = rs.getString("category");
                            java.sql.Date eventDate = rs.getDate("event_date");
                            String eventTime = rs.getString("event_time");
                            String venue = rs.getString("venue");
                            String status = rs.getString("status");
                %>

                    <tr>
                        <td>
                            <%= esc(eventName == null
                                ? "Unnamed Event" : eventName) %>
                        </td>

                        <td>
                            <%= esc(category == null
                                ? "General" : category) %>
                        </td>

                        <td>
                            <%= eventDate == null
                                ? "To be announced"
                                : eventDate.toString() %>
                        </td>

                        <td>
                            <%= esc(eventTime == null ||
                                eventTime.trim().isEmpty()
                                ? "To be announced" : eventTime) %>
                        </td>

                        <td>
                            <%= esc(venue == null ||
                                venue.trim().isEmpty()
                                ? "To be announced" : venue) %>
                        </td>

                        <td>
                            <span class="registration-status">
                                <%= esc(status == null
                                    ? "Pending" : status) %>
                            </span>
                        </td>
                    </tr>

                <%
                        }

                    } catch (Exception e) {
                        application.log(
                            "Unable to load registrations for user ID: " + uid,
                            e
                        );
                %>

                    <tr>
                        <td colspan="6">
                            <div class="registrations-error">
                                Unable to load your registrations.
                                Please check the database configuration
                                and the Tomcat console.
                            </div>
                        </td>
                    </tr>

                <%
                    } finally {
                        if (rs != null) {
                            try {
                                rs.close();
                            } catch (SQLException ignored) {
                            }
                        }

                        if (ps != null) {
                            try {
                                ps.close();
                            } catch (SQLException ignored) {
                            }
                        }

                        if (con != null) {
                            try {
                                con.close();
                            } catch (SQLException ignored) {
                            }
                        }
                    }

                    if (!found) {
                %>

                    <tr>
                        <td colspan="6">
                            <div class="registrations-empty">
                                You have not registered for any events yet.
                                <a href="events.jsp">Explore upcoming events</a>
                            </div>
                        </td>
                    </tr>

                <%
                    }
                %>

                </tbody>
            </table>

        </div>
    </div>

</main>

<footer class="footer">
    College Event Management System
</footer>

</body>
</html>
