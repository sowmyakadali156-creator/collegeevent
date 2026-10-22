
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="includes/db.jspf" %>

<%
    String msg = request.getParameter("msg");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Upcoming College Events</title>
    <link rel="stylesheet" href="assets/style.css">

    <style>
        .events-heading {
            text-align: center;
            margin: 30px 0;
        }

        .event-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            align-items: stretch;
            gap: 25px;
            margin-top: 30px;
        }

        .event-card {
            display: flex;
            flex-direction: column;
            height: 100%;
            box-sizing: border-box;
            background: #fff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 5px 20px rgba(0, 0, 0, 0.08);
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .event-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 28px rgba(0, 0, 0, 0.13);
        }

        .event-image {
            display: block;
            width: 100%;
            height: 220px;
            object-fit: cover;
            flex-shrink: 0;
        }

        .event-content {
            padding: 22px;
            display: flex;
            flex-direction: column;
            flex: 1;
        }

        .event-content h2 {
            margin-top: 0;
            margin-bottom: 12px;
            min-height: 2.4em;
        }

        .event-category {
            display: inline-block;
            background: #fff0d7;
            color: #874600;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: bold;
            margin-bottom: 12px;
            align-self: flex-start;
        }

        .event-description {
            line-height: 1.6;
            min-height: 3.2em;
            overflow-wrap: anywhere;
        }

        .event-details {
            line-height: 1.8;
            margin: 15px 0;
            overflow-wrap: anywhere;
        }

        .event-details p {
            margin: 5px 0;
        }

        .event-actions {
            margin-top: auto;
            padding-top: 18px;
        }

        .event-actions form {
            margin: 0;
        }

        .event-actions .btn {
            display: inline-block;
            text-align: center;
            cursor: pointer;
        }

        .success-message {
            background: #e7f8ed;
            color: #176534;
            border: 1px solid #a9dfb9;
            border-radius: 10px;
            padding: 14px 18px;
            margin: 20px 0;
        }

        .error-message {
            background: #fff0e9;
            color: #a33b18;
            border: 1px solid #f2c6b7;
            border-radius: 10px;
            padding: 14px 18px;
            margin: 20px 0;
        }

        @media (max-width: 1000px) {
            .event-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
        }

        @media (max-width: 600px) {
            .event-grid {
                grid-template-columns: 1fr;
            }

            .event-image {
                height: 200px;
            }
        }
    </style>
</head>

<body>

<%@ include file="includes/header.jspf" %>

<section class="section">

    <div class="events-heading">
        <h1>Upcoming College Events</h1>
        <p class="muted">
            Discover events, showcase your talent, learn new skills,
            and create unforgettable college memories.
        </p>
    </div>

    <% if ("registered".equalsIgnoreCase(msg)) { %>
        <div class="success-message">
            Registration successful! You have registered for the event.
        </div>
    <% } else if ("already".equalsIgnoreCase(msg)) { %>
        <div class="error-message">
            You have already registered for this event.
        </div>
    <% } else if ("login".equalsIgnoreCase(msg)) { %>
        <div class="error-message">
            Please log in before registering for an event.
        </div>
    <% } %>

    <div class="event-grid">

    <%
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = openConnection();

            ps = con.prepareStatement(
                "SELECT event_id, event_name, category, description, " +
                "event_date, event_time, venue, image_url " +
                "FROM events " +
                "WHERE UPPER(TRIM(status)) = 'ACTIVE' " +
                "ORDER BY event_date"
            );

            rs = ps.executeQuery();

            boolean found = false;

            while (rs.next()) {
                found = true;

                int eventId = rs.getInt("event_id");
                String eventName = rs.getString("event_name");
                String category = rs.getString("category");
                String description = rs.getString("description");
                String eventTime = rs.getString("event_time");
                String venue = rs.getString("venue");
                java.sql.Date eventDate = rs.getDate("event_date");
                String imageUrl = rs.getString("image_url");

                String eventKey = eventName == null
                    ? ""
                    : eventName.toLowerCase(java.util.Locale.ROOT);

                // Use the custom image URL first.
                String eventImage = imageUrl;

                if (eventImage == null || eventImage.trim().isEmpty()) {

                    if (eventKey.contains("hackathon") ||
                        eventKey.contains("codesprint")) {

                        eventImage =
                            "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=900";

                    } else if (eventKey.contains("paper") ||
                               eventKey.contains("presentation")) {

                        eventImage =
                            "https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=900";

                    } else if (eventKey.contains("project") ||
                               eventKey.contains("expo")) {

                        eventImage =
                            "https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=900";

                    } else if (eventKey.contains("poster") ||
                               eventKey.contains("design")) {

                        eventImage =
                            "https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=900";

                    } else if (eventKey.contains("workshop")) {

                        eventImage =
                            "https://images.unsplash.com/photo-1531482615713-2afd69097998?w=900";

                    } else if (eventKey.contains("robo")) {

                        eventImage =
                            "https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=900";

                    } else if (eventKey.contains("quiz")) {

                        eventImage =
                            "https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=900";

                    } else if (eventKey.contains("photo")) {

                        eventImage =
                            "https://images.unsplash.com/photo-1452587925148-ce544e77e70d?w=900";

                    } else if (eventKey.contains("cultural") ||
                               eventKey.contains("music") ||
                               eventKey.contains("dance")) {

                        eventImage =
                            "https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=900";

                    } else if (eventKey.contains("startup") ||
                               eventKey.contains("pitch")) {

                        eventImage =
                            "https://images.unsplash.com/photo-1556761175-b413da4baf72?w=900";

                    } else if (eventKey.contains("cyber") ||
                               eventKey.contains("security") ||
                               eventKey.contains("ctf")) {

                        eventImage =
                            "https://images.unsplash.com/photo-1510511459019-5dda7724fd87?w=900";

                    } else if (eventKey.contains("sport")) {

                        eventImage =
                            "https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=900";

                    } else {

                        eventImage =
                            "https://images.unsplash.com/photo-1523580494863-6f3031224c94?w=900";
                    }
                }

                String safeImage = esc(eventImage);
                String safeName = esc(
                    eventName == null ? "College Event" : eventName
                );
    %>

        <article class="event-card">

            <img
                class="event-image"
                src="<%= safeImage %>"
                alt="Image for <%= safeName %>"
                loading="lazy"
                onerror="this.onerror=null;this.src='https://images.unsplash.com/photo-1523580494863-6f3031224c94?w=900';"
            >

            <div class="event-content">

                <span class="event-category">
                    <%= esc(category == null ? "College Event" : category) %>
                </span>

                <h2><%= safeName %></h2>

                <p class="event-description">
                    <%= esc(description == null
                        ? "Join us for this exciting college event."
                        : description) %>
                </p>

                <div class="event-details">

                    <p>
                        <strong>Date:</strong>
                        <%= eventDate == null
                            ? "To be announced"
                            : eventDate.toString() %>
                    </p>

                    <p>
                        <strong>Time:</strong>
                        <%= esc(eventTime == null || eventTime.trim().isEmpty()
                            ? "To be announced"
                            : eventTime) %>
                    </p>

                    <p>
                        <strong>Venue:</strong>
                        <%= esc(venue == null || venue.trim().isEmpty()
                            ? "To be announced"
                            : venue) %>
                    </p>

                </div>

                <div class="event-actions">

                    <% if (session.getAttribute("userId") != null) { %>

                        <form method="get" action="registerEvent.jsp">
                            <input
                                type="hidden"
                                name="eventId"
                                value="<%= eventId %>"
                            >

                            <button type="submit" class="btn">
                                Register Now
                            </button>
                        </form>

                    <% } else { %>

                        <a class="btn" href="login.jsp?msg=login">
                            Login to Register
                        </a>

                    <% } %>

                </div>

            </div>

        </article>

    <%
            }

            if (!found) {
    %>

        <p>No active events are available at the moment.</p>

    <%
            }

        } catch (Exception e) {

            application.log("Error loading college events", e);
    %>

        <p class="error-message">
            Could not load events. Please check the Oracle database
            connection, the EVENTS table, and the Eclipse Console.
        </p>

    <%
        } finally {

            if (rs != null) {
                try {
                    rs.close();
                } catch (Exception ex) {
                    // Ignore close error
                }
            }

            if (ps != null) {
                try {
                    ps.close();
                } catch (Exception ex) {
                    // Ignore close error
                }
            }

            if (con != null) {
                try {
                    con.close();
                } catch (Exception ex) {
                    // Ignore close error
                }
            }
        }
    %>

    </div>
</section>

<footer class="footer">
    College Event Management System
</footer>

</body>
</html>
