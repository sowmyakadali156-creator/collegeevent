
<%@ page contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="includes/db.jspf" %>

<%
    String role = String.valueOf(session.getAttribute("role"));

    if (!"STUDENT".equalsIgnoreCase(role.trim())) {
        response.sendRedirect("login.jsp");
        return;
    }

    String userIdText = String.valueOf(session.getAttribute("userId"));
    int userId;

    try {
        userId = Integer.parseInt(userIdText);
    } catch (Exception e) {
        response.sendRedirect("login.jsp");
        return;
    }

    String message = null;
    String error = null;

    // Mark a notification as read.
    if ("POST".equalsIgnoreCase(request.getMethod())
            && "markRead".equals(request.getParameter("action"))) {

        String notificationIdText =
            request.getParameter("notificationId");

        try {
            int notificationId =
                Integer.parseInt(notificationIdText);

            try (Connection con = openConnection();
                 PreparedStatement ps = con.prepareStatement(
                     "UPDATE notifications SET is_read = 'Y' " +
                     "WHERE notification_id = ? AND user_id = ?")) {

                ps.setInt(1, notificationId);
                ps.setInt(2, userId);

                int rows = ps.executeUpdate();

                message = rows > 0
                    ? "Notification marked as read."
                    : "Notification was not found.";
            }
        } catch (Exception e) {
            application.log("Error marking notification as read", e);
            error = "Unable to update the notification.";
        }
    }

    int unreadCount = 0;

    try (Connection con = openConnection();
         PreparedStatement ps = con.prepareStatement(
             "SELECT COUNT(*) FROM notifications " +
             "WHERE user_id = ? AND is_read = 'N'")) {

        ps.setInt(1, userId);

        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                unreadCount = rs.getInt(1);
            }
        }
    } catch (Exception e) {
        application.log("Error counting notifications", e);
        error = "Unable to load the unread notification count.";
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">
    <title>Notifications - CampusEvents</title>
    <link rel="stylesheet" href="assets/style.css">

    <style>
        .notification-container {
            max-width: 900px;
            margin: 30px auto;
            padding: 20px;
        }

        .notification-heading {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 24px;
        }

        .notification-heading h1 {
            margin: 0;
            color: #172554;
        }

        .notification-count {
            padding: 8px 13px;
            background: #e0e7ff;
            color: #273c75;
            border-radius: 20px;
            font-weight: 700;
        }

        .notification-item {
            margin-bottom: 14px;
            padding: 20px;
            background: #fff;
            border: 1px solid #e5e9f2;
            border-radius: 12px;
            box-shadow: 0 4px 14px rgba(23,33,63,.05);
        }

        .notification-item.unread {
            border-left: 5px solid #2563eb;
            background: #f5f8ff;
        }

        .notification-item h3 {
            margin: 0 0 9px;
            color: #172554;
        }

        .notification-item p {
            line-height: 1.6;
            overflow-wrap: anywhere;
        }

        .notification-meta {
            color: #69758c;
            font-size: 13px;
        }

        .notification-actions {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
            margin-top: 12px;
        }

        .notification-actions a {
            color: #2563eb;
            text-decoration: none;
            font-weight: 600;
        }

        .notification-actions button {
            padding: 8px 12px;
            border: 0;
            border-radius: 7px;
            background: #2563eb;
            color: white;
            cursor: pointer;
        }

        .notification-alert {
            margin-bottom: 16px;
            padding: 12px;
            border-radius: 8px;
            background: #dcfce7;
            color: #166534;
        }

        .notification-error {
            background: #fee2e2;
            color: #991b1b;
        }

        .notification-empty {
            padding: 30px;
            text-align: center;
            background: white;
            border: 1px solid #e5e9f2;
            border-radius: 12px;
        }
    </style>
</head>

<body>

<%@ include file="includes/header.jspf" %>

<main class="notification-container">

    <div class="notification-heading">
        <h1>Notifications</h1>
        <span class="notification-count">
            <%= unreadCount %> unread
        </span>
    </div>

    <% if (message != null) { %>
        <div class="notification-alert">
            <%= esc(message) %>
        </div>
    <% } %>

    <% if (error != null) { %>
        <div class="notification-alert notification-error">
            <%= esc(error) %>
        </div>
    <% } %>

    <%
        boolean hasNotifications = false;

        try (Connection con = openConnection();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT notification_id, event_title, message, " +
                 "notification_type, is_read, created_at " +
                 "FROM notifications WHERE user_id = ? " +
                 "ORDER BY created_at DESC, notification_id DESC")) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    hasNotifications = true;

                    int notificationId =
                        rs.getInt("notification_id");

                    String title = rs.getString("event_title");
                    String body = rs.getString("message");
                    String type = rs.getString("notification_type");
                    String readStatus = rs.getString("is_read");
                    Timestamp createdAt =
                        rs.getTimestamp("created_at");

                    boolean unread = "N".equalsIgnoreCase(readStatus);
    %>

        <article class="notification-item <%= unread ? "unread" : "" %>">

            <h3><%= esc(title) %></h3>

            <p><%= esc(body) %></p>

            <div class="notification-meta">
                <%= esc(type) %>
                &middot;
                <%= createdAt == null
                    ? ""
                    : esc(createdAt.toString()) %>
                &middot;
                <%= unread ? "Unread" : "Read" %>
            </div>

            <div class="notification-actions">
                <a href="events.jsp">View events</a>

                <% if (unread) { %>
                    <form method="post" action="notifications.jsp">
                        <input type="hidden"
                               name="action"
                               value="markRead">

                        <input type="hidden"
                               name="notificationId"
                               value="<%= notificationId %>">

                        <button type="submit">
                            Mark as read
                        </button>
                    </form>
                <% } %>
            </div>

        </article>

    <%
                }
            }
        } catch (Exception e) {
            application.log("Error loading notifications", e);
    %>

        <div class="notification-alert notification-error">
            Unable to load notifications. Please try again.
        </div>

    <%
        }

        if (!hasNotifications) {
    %>
        <div class="notification-empty">
            <h3>No notifications yet</h3>
            <p>New college event announcements will appear here.</p>
        </div>
    <%
        }
    %>

    <p>
        <a href="userDashboard.jsp">Back to dashboard</a>
    </p>

</main>
</body>
</html>
