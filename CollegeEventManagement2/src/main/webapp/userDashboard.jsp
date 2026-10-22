
<%@ page contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ include file="includes/db.jspf" %>

<%
    String role = (String) session.getAttribute("role");

    if (!"STUDENT".equalsIgnoreCase(
            role == null ? "" : role.trim())
            || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int userId = ((Number) session.getAttribute("userId")).intValue();
    String userName = (String) session.getAttribute("userName");

    int upcomingCount = 0;
    int registrationCount = 0;
    int dashboardUnreadCount = 0;
    String dbError = null;

    try (Connection con = openConnection()) {

        // Count upcoming events.
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM events " +
                "WHERE event_date >= TRUNC(SYSDATE)");
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                upcomingCount = rs.getInt(1);
            }
        }

        // Count registrations made by this student.
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM registrations WHERE user_id = ?")) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    registrationCount = rs.getInt(1);
                }
            }
        }

        // Count unread notifications for this student.
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM notifications " +
                "WHERE user_id = ? AND is_read = 'N'")) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    dashboardUnreadCount = rs.getInt(1);
                }
            }
        }

    } catch (Exception e) {
        application.log("Student dashboard statistics error", e);
        dbError = "Dashboard information is temporarily unavailable.";
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>Student Dashboard - CampusEvents</title>

    <link rel="stylesheet" href="assets/style.css">

    <style>
        .notification-bell-link {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 9px;
            padding: 12px 18px;
            border: 1px solid #dbe3f0;
            border-radius: 10px;
            background: #ffffff;
            color: #172554;
            text-decoration: none;
            font-weight: 700;
            transition: background 0.2s ease;
        }

        .notification-bell-link:hover {
            background: #eef4ff;
        }

        .notification-bell-icon {
            font-size: 20px;
        }

        .notification-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 23px;
            height: 23px;
            padding: 0 6px;
            box-sizing: border-box;
            border-radius: 50px;
            background: #dc2626;
            color: #ffffff;
            font-size: 12px;
            font-weight: 700;
        }

        .notification-section {
            margin-top: 20px;
            margin-bottom: 25px;
        }
    </style>
</head>

<body>

<%@ include file="includes/header.jspf" %>

<main class="student-dashboard">

    <!-- Welcome Section -->
    <section class="dashboard-hero">
        <div class="hero-content">

            <span class="hero-label">
                YOUR CAMPUS, YOUR EVENTS
            </span>

            <h1>
                Welcome back,<br>
                <%= esc(userName == null ? "Student" : userName) %>!
            </h1>

            <p>
                Discover exciting campus activities, meet new people,
                and make your college experience memorable.
            </p>

            <div class="hero-actions">

                <a class="btn" href="events.jsp">
                    Explore Events
                </a>

                <a class="btn btn-outline"
                   href="myRegistrations.jsp">
                    My Registrations
                </a>

                <!-- Notification Bell -->
                
<a class="notification-bell-link" href="notifications.jsp">
    <span aria-hidden="true">&#128276;</span>
    Notifications

    <% if (dashboardUnreadCount > 0) { %>
        <span class="notification-badge">
            <%= dashboardUnreadCount %>
        </span>
    <% } %>
</a>
                
            </div>
        </div>
    </section>

    <!-- Dashboard Content -->
    <section class="dashboard-content">

        <div class="section-heading">
            <div>
                <h2>Your Dashboard</h2>
                <p>Here's what's happening on your campus.</p>
            </div>
        </div>

        <% if (dbError != null) { %>
            <p class="error"><%= esc(dbError) %></p>
        <% } %>

        <!-- Notification Summary -->
        <div class="notification-section">
            <a class="notification-bell-link"
               href="notifications.jsp">

                <span aria-hidden="true">&#128276;</span>

                <% if (dashboardUnreadCount > 0) { %>
                    You have <%= dashboardUnreadCount %>
                    unread notification(s)
                <% } else { %>
                    You have no unread notifications
                <% } %>

            </a>
        </div>

        <!-- Dashboard Statistics -->
        <div class="dashboard-stats">

            <article class="stat-card">
                <div class="stat-icon">🎉</div>
                <div>
                    <p>Upcoming Events</p>
                    <h3><%= upcomingCount %></h3>
                    <a href="events.jsp">Discover events →</a>
                </div>
            </article>

            <article class="stat-card">
                <div class="stat-icon">📋</div>
                <div>
                    <p>My Registrations</p>
                    <h3><%= registrationCount %></h3>
                    <a href="myRegistrations.jsp">
                        View registrations →
                    </a>
                </div>
            </article>

            <article class="stat-card">
                <div class="stat-icon">✨</div>
                <div>
                    <p>Make the Most of College</p>
                    <h3>Get Involved</h3>
                    <a href="events.jsp">
                        Find your next event →
                    </a>
                </div>
            </article>

        </div>

        <!-- Upcoming Events Heading -->
        <div class="section-heading events-heading">
            <div>
                <h2>Upcoming Events</h2>
                <p>Find something interesting to participate in.</p>
            </div>

            <a class="view-all" href="events.jsp">
                View All Events →
            </a>
        </div>

        <!-- Upcoming Events -->
        <div class="event-grid">

            <%
                boolean foundEvents = false;

                try (Connection con = openConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "SELECT event_id, event_name, category, " +
                         "description, event_date, event_time, venue " +
                         "FROM (" +
                         " SELECT event_id, event_name, category, " +
                         " description, event_date, event_time, venue " +
                         " FROM events " +
                         " WHERE event_date >= TRUNC(SYSDATE) " +
                         " ORDER BY event_date ASC" +
                         ") WHERE ROWNUM <= 3");
                     ResultSet rs = ps.executeQuery()) {

                    while (rs.next()) {
                        foundEvents = true;

                        int eventId = rs.getInt("event_id");
                        String eventName = rs.getString("event_name");
                        String category = rs.getString("category");
                        String description = rs.getString("description");
                        java.sql.Date eventDate =
                            rs.getDate("event_date");
                        String eventTime = rs.getString("event_time");
                        String venue = rs.getString("venue");
            %>

                <article class="event-card">

                    <div class="event-card-top">
                        <span class="event-category">
                            <%= esc(category == null
                                    ? "Campus Event" : category) %>
                        </span>

                        <span class="event-symbol">★</span>
                    </div>

                    <div class="event-card-body">

                        <h3>
                            <%= esc(eventName == null
                                    ? "Campus Event" : eventName) %>
                        </h3>

                        <p class="event-description">
                            <%= esc(description == null
                                    || description.trim().isEmpty()
                                    ? "Join us and take part in this campus event."
                                    : description) %>
                        </p>

                        <div class="event-detail">
                            <span>📅</span>
                            <span>
                                <%= eventDate == null
                                    ? "Date to be announced"
                                    : new SimpleDateFormat("dd MMM yyyy")
                                        .format(eventDate) %>
                            </span>
                        </div>

                        <div class="event-detail">
                            <span>🕒</span>
                            <span>
                                <%= esc(eventTime == null
                                        || eventTime.trim().isEmpty()
                                        ? "Time to be announced"
                                        : eventTime) %>
                            </span>
                        </div>

                        <div class="event-detail">
                            <span>📍</span>
                            <span>
                                <%= esc(venue == null
                                        || venue.trim().isEmpty()
                                        ? "Venue to be announced"
                                        : venue) %>
                            </span>
                        </div>

                        <a class="event-link"
                           href="registerEvent.jsp?eventId=<%= eventId %>">
                            View / Register for Event →
                        </a>

                    </div>
                </article>

            <%
                    }
                } catch (Exception e) {
                    application.log(
                        "Upcoming events loading error", e);
                }
            %>

            <% if (!foundEvents) { %>
                <div class="empty-events">
                    <div class="empty-icon">🎈</div>

                    <h3>New experiences are waiting!</h3>

                    <p>
                        There are no upcoming events to display right now.
                        Check the events page for updates.
                    </p>

                    <a class="btn" href="events.jsp">
                        Browse All Events
                    </a>
                </div>
            <% } %>

        </div>

        <!-- Bottom Call to Action -->
        <section class="dashboard-cta">
            <div>
                <h2>Don't miss out on campus life!</h2>
                <p>
                    Explore upcoming events and find your next experience.
                </p>
            </div>

            <a class="btn" href="events.jsp">
                Explore Events →
            </a>
        </section>

    </section>
</main>

<footer class="footer">
    CampusEvents · College Event Management System
</footer>

</body>
</html>
