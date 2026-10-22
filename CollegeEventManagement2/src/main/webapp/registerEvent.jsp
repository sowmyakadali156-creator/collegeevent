
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.time.LocalDate" %>
<%@ include file="includes/db.jspf" %>

<%
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String message = "";
String messageType = "";
String eventName = "";
String eventDate = "";
String eventTime = "";
String venue = "";

String eventIdParam = request.getParameter("eventId");

if (eventIdParam == null || eventIdParam.trim().isEmpty()) {
    response.sendRedirect("events.jsp");
    return;
}

int eventId;

try {
    eventId = Integer.parseInt(eventIdParam);
} catch (NumberFormatException ex) {
    response.sendRedirect("events.jsp");
    return;
}

/* Load selected event details */
try (Connection con = openConnection();
     PreparedStatement ps = con.prepareStatement(
         "SELECT event_name, event_date, event_time, venue " +
         "FROM events WHERE event_id = ? AND status = 'ACTIVE'")) {

    ps.setInt(1, eventId);

    try (ResultSet rs = ps.executeQuery()) {
        if (rs.next()) {
            eventName = rs.getString("event_name");
            eventDate = rs.getString("event_date");
            eventTime = rs.getString("event_time");
            venue = rs.getString("venue");
        } else {
            response.sendRedirect("events.jsp?msg=EventUnavailable");
            return;
        }
    }
} catch (Exception ex) {
    message = "Unable to load event details. Please check the database connection.";
    messageType = "error";
}

/* Save registration */
if ("POST".equalsIgnoreCase(request.getMethod())) {

    String fullName = request.getParameter("fullName");
    String email = request.getParameter("email");
    String department = request.getParameter("department");
    String rollNumber = request.getParameter("rollNumber");
    String section = request.getParameter("section");
    String year = request.getParameter("year");
    String mobile = request.getParameter("mobile");
    String gender = request.getParameter("gender");

    if (fullName == null || fullName.trim().isEmpty()
        || email == null || email.trim().isEmpty()
        || department == null || rollNumber == null
        || section == null || year == null
        || mobile == null || gender == null) {

        message = "Please fill in all required fields.";
        messageType = "error";

    } else if (!mobile.trim().matches("[0-9]{10}")) {

        message = "Enter a valid 10-digit mobile number.";
        messageType = "error";

    } else {

        try (Connection con = openConnection()) {

            /* Prevent duplicate registrations for the same event */
            try (PreparedStatement check = con.prepareStatement(
                "SELECT registration_id FROM registrations " +
                "WHERE user_id = ? AND event_id = ?")) {

                check.setInt(1,
                    Integer.parseInt(session.getAttribute("userId").toString()));
                check.setInt(2, eventId);

                try (ResultSet rs = check.executeQuery()) {

                    if (rs.next()) {
                        message = "You have already registered for this event.";
                        messageType = "error";
                    } else {

                        /*
                         * This INSERT assumes your registrations table
                         * has the student detail columns shown below.
                         */
                        String sql =
                            "INSERT INTO registrations " +
                            "(user_id, event_id, full_name, email, department, " +
                            "roll_number, section, year_of_study, mobile, gender, " +
                            "registered_at, status) " +
                            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, 'REGISTERED')";

                        try (PreparedStatement ps = con.prepareStatement(sql)) {

                            ps.setInt(1, Integer.parseInt(
                                session.getAttribute("userId").toString()));
                            ps.setInt(2, eventId);
                            ps.setString(3, fullName.trim());
                            ps.setString(4, email.trim().toLowerCase());
                            ps.setString(5, department);
                            ps.setString(6, rollNumber.trim().toUpperCase());
                            ps.setString(7, section);
                            ps.setString(8, year);
                            ps.setString(9, mobile.trim());
                            ps.setString(10, gender);

                            ps.executeUpdate();
                        }

                        response.sendRedirect(
                            "registerEvent.jsp?eventId=" + eventId + "&success=1");
                        return;
                    }
                }
            }

        } catch (Exception ex) {
            message = "Registration failed. Please check the registrations table structure.";
            messageType = "error";
            application.log("Event registration failed", ex);
        }
    }
}

/* Show confirmation after successful database insertion */
if ("1".equals(request.getParameter("success"))) {
    message = "Registration successful! You have registered for " + eventName + ".";
    messageType = "success";
}
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Event Registration - CampusEvents</title>
    <link rel="stylesheet" href="assets/style.css">

    <style>
        .registration-container {
            max-width: 900px;
            margin: 35px auto;
            padding: 25px;
        }

        .registration-heading {
            margin-bottom: 8px;
        }

        .event-summary {
            background: #eef1ff;
            padding: 18px;
            border-radius: 12px;
            margin: 20px 0;
        }

        .registration-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 0 22px;
        }

        .registration-grid .field {
            margin: 12px 0;
        }

        .registration-grid input,
        .registration-grid select {
            width: 100%;
            min-height: 44px;
            padding: 11px;
            border: 1px solid #d9deea;
            border-radius: 8px;
            font: inherit;
        }

        .registration-grid input:focus,
        .registration-grid select:focus {
            outline: 2px solid #b8a8ff;
            border-color: #5b42a3;
        }

        .full-width {
            grid-column: 1 / -1;
        }

        .success-message {
            background: #e7f8ed;
            color: #17673a;
            padding: 16px;
            border-radius: 10px;
            margin: 18px 0;
        }

        .error-message {
            background: #fff0e8;
            color: #9a3b18;
            padding: 16px;
            border-radius: 10px;
            margin: 18px 0;
        }

        @media (max-width: 650px) {
            .registration-container {
                margin: 20px 12px;
                padding: 18px;
            }

            .registration-grid {
                grid-template-columns: 1fr;
            }

            .full-width {
                grid-column: auto;
            }
        }
    </style>
</head>

<body>

<%@ include file="includes/header.jspf" %>

<section class="registration-container">
    <div class="form-card" style="max-width:100%; margin:0;">

        <h1 class="registration-heading">Student Event Registration</h1>
        <p class="muted">Enter your details to register for the selected college event.</p>

        <% if (!message.isEmpty()) { %>
            <div class="<%= "success".equals(messageType)
                ? "success-message" : "error-message" %>">
                <%= message %>
            </div>
        <% } %>

        <% if ("1".equals(request.getParameter("success"))) { %>

            <div class="event-summary">
                <h2>Registration Confirmed!</h2>
                <p>Your registration has been submitted successfully.</p>
                <p><strong>Event:</strong> <%= eventName %></p>
                <p><strong>Date:</strong> <%= eventDate %></p>
                <p><strong>Time:</strong> <%= eventTime %></p>
                <p><strong>Venue:</strong> <%= venue %></p>
            </div>

            <a class="btn" href="events.jsp">Browse More Events</a>
            <a class="btn btn-secondary" href="myRegistrations.jsp">My Registrations</a>

        <% } else { %>

            <div class="event-summary">
                <h3>Selected Event: <%= eventName %></h3>
                <p><strong>Date:</strong> <%= eventDate %></p>
                <p><strong>Time:</strong> <%= eventTime %></p>
                <p><strong>Venue:</strong> <%= venue %></p>
            </div>

            <form method="post"
                  action="registerEvent.jsp?eventId=<%= eventId %>">

                <div class="registration-grid">

                    <div class="field">
                        <label for="fullName">Full Name *</label>
                        <input type="text" id="fullName" name="fullName"
                               maxlength="100" required>
                    </div>

                    <div class="field">
                        <label for="email">College Email *</label>
                        <input type="email" id="email" name="email"
                               maxlength="150" required>
                    </div>

                    <div class="field">
                        <label for="department">Department *</label>
                        <select id="department" name="department" required>
                            <option value="">Select Department</option>
                            <option value="CSE">CSE - Computer Science</option>
                            <option value="ECE">ECE - Electronics and Communication</option>
                            <option value="EEE">EEE - Electrical and Electronics</option>
                            <option value="AIDS">AI & Data Science</option>
                            <option value="AIML">AI & Machine Learning</option>
                            <option value="IT">Information Technology</option>
                            <option value="CIVIL">Civil Engineering</option>
                            <option value="MECH">Mechanical Engineering</option>
                            <option value="AEROSPACE">Aerospace Engineering</option>
                            <option value="CHEMICAL">Chemical Engineering</option>
                            <option value="BIOTECH">Biotechnology</option>
                            <option value="OTHER">Other</option>
                        </select>
                    </div>

                    <div class="field">
                        <label for="rollNumber">Roll Number *</label>
                        <input type="text" id="rollNumber" name="rollNumber"
                               maxlength="30" required>
                    </div>

                    <div class="field">
                        <label for="section">Section *</label>
                        <select id="section" name="section" required>
                            <option value="">Select Section</option>
                            <option value="A">Section A</option>
                            <option value="B">Section B</option>
                            <option value="C">Section C</option>
                            <option value="D">Section D</option>
                            <option value="E">Section E</option>
                            <option value="OTHER">Other</option>
                        </select>
                    </div>

                    <div class="field">
                        <label for="year">Year of Study *</label>
                        <select id="year" name="year" required>
                            <option value="">Select Year</option>
                            <option value="1st Year">1st Year</option>
                            <option value="2nd Year">2nd Year</option>
                            <option value="3rd Year">3rd Year</option>
                            <option value="4th Year">4th Year</option>
                        </select>
                    </div>

                    <div class="field">
                        <label for="mobile">Mobile Number *</label>
                        <input type="tel" id="mobile" name="mobile"
                               inputmode="numeric" pattern="[0-9]{10}"
                               minlength="10" maxlength="10"
                               placeholder="10-digit mobile number" required>
                    </div>

                    <div class="field">
                        <label for="gender">Gender *</label>
                        <select id="gender" name="gender" required>
                            <option value="">Select Gender</option>
                            <option value="Female">Female</option>
                            <option value="Male">Male</option>
                            <option value="Other">Other</option>
                            <option value="Prefer not to say">Prefer not to say</option>
                        </select>
                    </div>

                </div>

                <p class="muted">Fields marked * are mandatory.</p>

                <button type="submit" class="btn">
                    Confirm Registration
                </button>

                <a href="events.jsp" class="btn btn-secondary">
                    Cancel
                </a>

            </form>

        <% } %>

    </div>
</section>

<footer class="footer">College Event Management System</footer>

</body>
</html>