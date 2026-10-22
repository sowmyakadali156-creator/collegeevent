
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="includes/db.jspf" %>

<%
/* ADMIN ACCESS CONTROL */
String role = (String) session.getAttribute("role");

if (!"ADMIN".equalsIgnoreCase(role == null ? "" : role.trim())) {
    response.sendRedirect("login.jsp");
    return;
}

String adminName = (String) session.getAttribute("userName");
String error = null;
String success = null;

/* HANDLE ADMIN ACTIONS */
if ("POST".equalsIgnoreCase(request.getMethod())) {

    String action = request.getParameter("action");

    if ("addEvent".equals(action)) {

        String eventName = request.getParameter("eventName");
        String category = request.getParameter("category");
        String description = request.getParameter("description");
        String eventDate = request.getParameter("eventDate");
        String eventTime = request.getParameter("eventTime");
        String venue = request.getParameter("venue");
        String deadline = request.getParameter("registrationDeadline");
        String maxParticipants = request.getParameter("maxParticipants");
        String imageUrl = request.getParameter("imageUrl");

        if (eventName == null || eventName.trim().isEmpty()
                || category == null || category.trim().isEmpty()
                || eventDate == null || eventDate.trim().isEmpty()
                || venue == null || venue.trim().isEmpty()
                || maxParticipants == null
                || maxParticipants.trim().isEmpty()) {

            error = "Please fill in all required fields.";

        } else {
            try {
                int capacity = Integer.parseInt(maxParticipants.trim());

                if (capacity <= 0) {
                    error = "Maximum participants must be greater than zero.";
                } else {
                    try (Connection con = openConnection();
                         PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO events " +
                            "(event_name, category, description, event_date, " +
                            "event_time, venue, registration_deadline, " +
                            "max_participants, image_url, status) " +
                            "VALUES (?, ?, ?, TO_DATE(?, 'YYYY-MM-DD'), " +
                            "?, ?, TO_DATE(?, 'YYYY-MM-DD'), ?, ?, ?)")) {

                        ps.setString(1, eventName.trim());
                        ps.setString(2, category.trim());
                        ps.setString(3, description == null ? "" : description.trim());
                        ps.setString(4, eventDate.trim());

                        if (eventTime == null || eventTime.trim().isEmpty()) {
                            ps.setNull(5, Types.VARCHAR);
                        } else {
                            ps.setString(5, eventTime.trim());
                        }

                        ps.setString(6, venue.trim());

                        if (deadline == null || deadline.trim().isEmpty()) {
                            ps.setNull(7, Types.DATE);
                        } else {
                            ps.setString(7, deadline.trim());
                        }

                        ps.setInt(8, capacity);

                        if (imageUrl == null || imageUrl.trim().isEmpty()) {
                            ps.setNull(9, Types.VARCHAR);
                        } else {
                            ps.setString(9, imageUrl.trim());
                        }

                        ps.setString(10, "ACTIVE");
                        ps.executeUpdate();

                        success = "Event added successfully.";
                    }
                }

            } catch (NumberFormatException e) {
                error = "Maximum participants must be a valid number.";
            } catch (Exception e) {
                application.log("Error adding event", e);
                error = "Unable to add event. Check the database and event details.";
            }
        }

    } else if ("updateEvent".equals(action)) {

        String eventIdValue = request.getParameter("eventId");
        String eventName = request.getParameter("eventName");
        String category = request.getParameter("category");
        String description = request.getParameter("description");
        String eventDate = request.getParameter("eventDate");
        String eventTime = request.getParameter("eventTime");
        String venue = request.getParameter("venue");
        String deadline = request.getParameter("registrationDeadline");
        String maxParticipants = request.getParameter("maxParticipants");
        String imageUrl = request.getParameter("imageUrl");
        String status = request.getParameter("status");

        try {
            int eventId = Integer.parseInt(eventIdValue);
            int capacity = Integer.parseInt(maxParticipants);

            if (eventName == null || eventName.trim().isEmpty()
                    || category == null || category.trim().isEmpty()
                    || eventDate == null || eventDate.trim().isEmpty()
                    || venue == null || venue.trim().isEmpty()
                    || capacity <= 0
                    || !("ACTIVE".equals(status) || "INACTIVE".equals(status))) {

                error = "Please enter valid event details.";

            } else {
                try (Connection con = openConnection();
                     PreparedStatement ps = con.prepareStatement(
                        "UPDATE events SET event_name=?, category=?, description=?, " +
                        "event_date=TO_DATE(?, 'YYYY-MM-DD'), event_time=?, venue=?, " +
                        "registration_deadline=TO_DATE(?, 'YYYY-MM-DD'), " +
                        "max_participants=?, image_url=?, status=? WHERE event_id=?")) {

                    ps.setString(1, eventName.trim());
                    ps.setString(2, category.trim());
                    ps.setString(3, description == null ? "" : description.trim());
                    ps.setString(4, eventDate.trim());

                    if (eventTime == null || eventTime.trim().isEmpty()) {
                        ps.setNull(5, Types.VARCHAR);
                    } else {
                        ps.setString(5, eventTime.trim());
                    }

                    ps.setString(6, venue.trim());

                    if (deadline == null || deadline.trim().isEmpty()) {
                        ps.setNull(7, Types.DATE);
                    } else {
                        ps.setString(7, deadline.trim());
                    }

                    ps.setInt(8, capacity);

                    if (imageUrl == null || imageUrl.trim().isEmpty()) {
                        ps.setNull(9, Types.VARCHAR);
                    } else {
                        ps.setString(9, imageUrl.trim());
                    }

                    ps.setString(10, status);
                    ps.setInt(11, eventId);

                    int rows = ps.executeUpdate();

                    if (rows > 0) {
                        success = "Event updated successfully.";
                    } else {
                        error = "Event not found.";
                    }
                }
            }

        } catch (NumberFormatException e) {
            error = "Invalid event ID or maximum participants.";
        } catch (Exception e) {
            application.log("Error updating event", e);
            error = "Unable to update event. Check the database and event details.";
        }

    } else if ("deleteEvent".equals(action)) {

        String eventIdValue = request.getParameter("eventId");

        try {
            int eventId = Integer.parseInt(eventIdValue);

            try (Connection con = openConnection()) {
                con.setAutoCommit(false);

                try {
                    try (PreparedStatement ps = con.prepareStatement(
                            "DELETE FROM registrations WHERE event_id = ?")) {
                        ps.setInt(1, eventId);
                        ps.executeUpdate();
                    }

                    int rows;

                    try (PreparedStatement ps = con.prepareStatement(
                            "DELETE FROM events WHERE event_id = ?")) {
                        ps.setInt(1, eventId);
                        rows = ps.executeUpdate();
                    }

                    if (rows > 0) {
                        con.commit();
                        success = "Event and its registrations deleted successfully.";
                    } else {
                        con.rollback();
                        error = "Event not found.";
                    }

                } catch (Exception e) {
                    con.rollback();
                    throw e;
                }
            }

        } catch (NumberFormatException e) {
            error = "Invalid event ID.";
        } catch (Exception e) {
            application.log("Error deleting event", e);
            error = "Unable to delete event.";
        }

    } else {
        error = "Invalid action.";
    }
}

/* LOAD EVENT DETAILS FOR EDITING */
boolean editingEvent = false;
int editEventId = 0;
String formEventName = "";
String formCategory = "";
String formDescription = "";
String formEventDate = "";
String formEventTime = "";
String formVenue = "";
String formDeadline = "";
String formMaxParticipants = "";
String formImageUrl = "";
String formStatus = "ACTIVE";

String editIdParam = request.getParameter("editEventId");

if ("GET".equalsIgnoreCase(request.getMethod())
        && editIdParam != null && !editIdParam.trim().isEmpty()) {

    try {
        editEventId = Integer.parseInt(editIdParam.trim());

        try (Connection con = openConnection();
             PreparedStatement ps = con.prepareStatement(
                "SELECT event_name, category, description, event_date, event_time, " +
                "venue, registration_deadline, max_participants, image_url, status " +
                "FROM events WHERE event_id = ?")) {

            ps.setInt(1, editEventId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    editingEvent = true;
                    formEventName = rs.getString("event_name");
                    formCategory = rs.getString("category");
                    formDescription = rs.getString("description");

                    java.sql.Date eventSqlDate = rs.getDate("event_date");
                    java.sql.Date deadlineSqlDate = rs.getDate("registration_deadline");

                    formEventDate = eventSqlDate == null ? "" :
                        new java.text.SimpleDateFormat("yyyy-MM-dd").format(eventSqlDate);

                    formDeadline = deadlineSqlDate == null ? "" :
                        new java.text.SimpleDateFormat("yyyy-MM-dd").format(deadlineSqlDate);

                    formEventTime = rs.getString("event_time");
                    formVenue = rs.getString("venue");

                    int storedCapacity = rs.getInt("max_participants");
                    formMaxParticipants = rs.wasNull() ? "" : String.valueOf(storedCapacity);

                    formImageUrl = rs.getString("image_url");
                    formStatus = rs.getString("status");

                    if (formStatus == null || formStatus.trim().isEmpty()) {
                        formStatus = "ACTIVE";
                    }

                } else {
                    error = "Event not found for editing.";
                }
            }
        }

    } catch (NumberFormatException e) {
        error = "Invalid event ID.";
    } catch (Exception e) {
        application.log("Error loading event for editing", e);
        error = "Unable to load event details for editing.";
    }
}

/* DASHBOARD STATISTICS */
int totalEvents = 0;
int activeEvents = 0;
int totalRegistrations = 0;
int totalStudents = 0;

try (Connection con = openConnection()) {

    try (PreparedStatement ps = con.prepareStatement(
            "SELECT COUNT(*), " +
            "NVL(SUM(CASE WHEN status = 'ACTIVE' THEN 1 ELSE 0 END), 0) " +
            "FROM events");
         ResultSet rs = ps.executeQuery()) {

        if (rs.next()) {
            totalEvents = rs.getInt(1);
            activeEvents = rs.getInt(2);
        }
    }

    try (PreparedStatement ps = con.prepareStatement(
            "SELECT COUNT(*), COUNT(DISTINCT user_id) FROM registrations");
         ResultSet rs = ps.executeQuery()) {

        if (rs.next()) {
            totalRegistrations = rs.getInt(1);
            totalStudents = rs.getInt(2);
        }
    }

} catch (Exception e) {
    application.log("Error loading admin statistics", e);
    if (error == null) {
        error = "Some dashboard statistics could not be loaded.";
    }
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard - CampusEvents</title>
    <link rel="stylesheet" href="assets/style.css">

    <style>
        .admin-container {
            max-width: 1250px;
            margin: 30px auto;
            padding: 20px;
        }

        .admin-heading {
            margin-bottom: 25px;
        }

        .admin-heading h1 {
            margin-bottom: 8px;
            color: #17213f;
        }

        .admin-muted {
            color: #69758c;
            line-height: 1.6;
        }

        .admin-links {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 25px;
        }

        .admin-links a {
            text-decoration: none;
        }

        .admin-stats {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 18px;
            margin-bottom: 30px;
        }

        .admin-stat {
            padding: 22px;
            background: #ffffff;
            border: 1px solid #e5e9f2;
            border-radius: 12px;
            box-shadow: 0 4px 16px rgba(23, 33, 63, 0.05);
        }

        .admin-stat p {
            margin: 0 0 12px;
            color: #69758c;
        }

        .admin-stat h2 {
            margin: 0;
            color: #17213f;
            font-size: 30px;
        }

        .admin-card {
            margin-bottom: 28px;
            padding: 25px;
            background: #ffffff;
            border: 1px solid #e5e9f2;
            border-radius: 12px;
            box-shadow: 0 4px 16px rgba(23, 33, 63, 0.05);
        }

        .admin-card h2 {
            margin-top: 0;
            margin-bottom: 20px;
            color: #17213f;
        }

        .admin-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 18px;
        }

        .admin-form-field {
            margin-bottom: 16px;
        }

        .admin-form-field label {
            display: block;
            margin-bottom: 7px;
            font-weight: 600;
        }

        .admin-form-field input,
        .admin-form-field select,
        .admin-form-field textarea {
            width: 100%;
            box-sizing: border-box;
            padding: 11px;
            border: 1px solid #cbd5e1;
            border-radius: 7px;
            font: inherit;
        }

        .admin-form-field textarea {
            min-height: 100px;
            resize: vertical;
        }

        .admin-table-wrapper {
            overflow-x: auto;
        }

        .admin-table {
            width: 100%;
            min-width: 1050px;
            border-collapse: collapse;
        }

        .admin-table th,
        .admin-table td {
            padding: 12px;
            border-bottom: 1px solid #e2e8f0;
            text-align: left;
            vertical-align: top;
        }

        .admin-table th {
            background: #f1f5f9;
            color: #17213f;
            white-space: nowrap;
        }

        .admin-table form {
            margin: 0;
        }

        .admin-edit {
            display: inline-block;
            padding: 8px 12px;
            margin-bottom: 6px;
            background: #2563eb;
            color: #ffffff;
            border: none;
            border-radius: 6px;
            text-decoration: none;
            cursor: pointer;
        }

        .admin-edit:hover {
            background: #1d4ed8;
        }

        .admin-delete {
            padding: 8px 12px;
            background: #dc2626;
            color: #ffffff;
            border: none;
            border-radius: 6px;
            cursor: pointer;
        }

        .admin-delete:hover {
            background: #b91c1c;
        }

        .admin-alert {
            padding: 13px 16px;
            margin-bottom: 18px;
            border-radius: 7px;
        }

        .admin-alert-error {
            background: #fee2e2;
            color: #991b1b;
        }

        .admin-alert-success {
            background: #dcfce7;
            color: #166534;
        }

        .admin-status {
            display: inline-block;
            padding: 5px 9px;
            background: #e8edf7;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }

        .admin-empty {
            padding: 22px;
            text-align: center;
            color: #69758c;
        }

        .registration-count-link {
            display: inline-block;
            padding: 7px 10px;
            border-radius: 6px;
            background: #e0e7ff;
            color: #3730a3;
            text-decoration: none;
            font-weight: 600;
            white-space: nowrap;
        }

        .registration-count-link:hover {
            background: #c7d2fe;
            text-decoration: underline;
        }

        .event-name-link {
            color: #2563eb;
            font-weight: 600;
            text-decoration: none;
        }

        .event-name-link:hover {
            text-decoration: underline;
        }

        @media (max-width: 850px) {
            .admin-stats {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
        }

        @media (max-width: 600px) {
            .admin-container {
                margin: 15px auto;
                padding: 12px;
            }

            .admin-card {
                padding: 16px;
            }

            .admin-grid,
            .admin-stats {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>

<body>

<%@ include file="includes/header.jspf" %>

<main class="admin-container">

    <section class="admin-heading">
        <h1>Admin Dashboard</h1>
        <p class="admin-muted">
            Welcome,
            <%= esc(adminName == null ? "Administrator" : adminName) %>.
            Manage college events and student registrations.
        </p>
    </section>

    <div class="admin-links">
        <a class="btn" href="events.jsp">View Events</a>
        <a class="btn" href="#add-event">Add New Event</a>
        <a class="btn" href="#registrations">Student Registrations</a>
        <a class="btn" href="#manage-events">Manage Events</a>
    </div>

    <% if (error != null) { %>
        <div class="admin-alert admin-alert-error">
            <%= esc(error) %>
        </div>
    <% } %>

    <% if (success != null) { %>
        <div class="admin-alert admin-alert-success">
            <%= esc(success) %>
        </div>
    <% } %>

    <!-- DASHBOARD SUMMARY -->
    <section class="admin-stats">

        <div class="admin-stat">
            <p>Total Events</p>
            <h2><%= totalEvents %></h2>
        </div>

        <div class="admin-stat">
            <p>Active Events</p>
            <h2><%= activeEvents %></h2>
        </div>

        <div class="admin-stat">
            <p>Total Registrations</p>
            <h2><%= totalRegistrations %></h2>
        </div>

        <div class="admin-stat">
            <p>Registered Students</p>
            <h2><%= totalStudents %></h2>
        </div>

    </section>

    <!-- ADD OR EDIT EVENT -->
    <section class="admin-card" id="add-event">
        <h2><%= editingEvent ? "Edit Event" : "Add New Event" %></h2>

        <form method="post" action="admin.jsp">
            <input type="hidden" name="action"
                   value="<%= editingEvent ? "updateEvent" : "addEvent" %>">

            <% if (editingEvent) { %>
                <input type="hidden" name="eventId" value="<%= editEventId %>">
            <% } %>

            <div class="admin-grid">

                <div class="admin-form-field">
                    <label for="eventName">Event Name *</label>
                    <input type="text" id="eventName" name="eventName"
                           value="<%= esc(formEventName) %>"
                           maxlength="150" required>
                </div>

                <div class="admin-form-field">
                    <label for="category">Category *</label>
                    <select id="category" name="category" required>
                        <option value="">Select Category</option>
                        <option value="Technical" <%= "Technical".equals(formCategory) ? "selected" : "" %>>Technical</option>
                        <option value="Cultural" <%= "Cultural".equals(formCategory) ? "selected" : "" %>>Cultural</option>
                        <option value="Sports" <%= "Sports".equals(formCategory) ? "selected" : "" %>>Sports</option>
                        <option value="Workshop" <%= "Workshop".equals(formCategory) ? "selected" : "" %>>Workshop</option>
                        <option value="Seminar" <%= "Seminar".equals(formCategory) ? "selected" : "" %>>Seminar</option>
                        <option value="Other" <%= "Other".equals(formCategory) ? "selected" : "" %>>Other</option>
                    </select>
                </div>

                <div class="admin-form-field">
                    <label for="eventDate">Event Date *</label>
                    <input type="date" id="eventDate" name="eventDate"
                           value="<%= esc(formEventDate) %>" required>
                </div>

                <div class="admin-form-field">
                    <label for="eventTime">Event Time</label>
                    <input type="time" id="eventTime" name="eventTime"
                           value="<%= esc(formEventTime) %>">
                </div>

                <div class="admin-form-field">
                    <label for="venue">Venue *</label>
                    <input type="text" id="venue" name="venue"
                           value="<%= esc(formVenue) %>" maxlength="150" required>
                </div>

                <div class="admin-form-field">
                    <label for="registrationDeadline">Registration Deadline</label>
                    <input type="date" id="registrationDeadline"
                           name="registrationDeadline"
                           value="<%= esc(formDeadline) %>">
                </div>

                <div class="admin-form-field">
                    <label for="maxParticipants">Maximum Participants *</label>
                    <input type="number" id="maxParticipants"
                           name="maxParticipants"
                           value="<%= esc(formMaxParticipants) %>"
                           min="1" required>
                </div>

                <div class="admin-form-field">
                    <label for="imageUrl">Image URL</label>
                    <input type="url" id="imageUrl" name="imageUrl"
                           value="<%= esc(formImageUrl) %>" maxlength="500">
                </div>

            </div>

            <div class="admin-form-field">
                <label for="description">Description</label>
                <textarea id="description" name="description"
                          maxlength="2000"><%= esc(formDescription) %></textarea>
            </div>

            <% if (editingEvent) { %>
                <div class="admin-form-field">
                    <label for="status">Event Status</label>
                    <select id="status" name="status" required>
                        <option value="ACTIVE" <%= "ACTIVE".equalsIgnoreCase(formStatus) ? "selected" : "" %>>ACTIVE</option>
                        <option value="INACTIVE" <%= "INACTIVE".equalsIgnoreCase(formStatus) ? "selected" : "" %>>INACTIVE</option>
                    </select>
                </div>

                <button type="submit" class="btn">Update Event</button>
                <a class="btn" href="admin.jsp">Cancel</a>
            <% } else { %>
                <button type="submit" class="btn">Add Event</button>
            <% } %>
        </form>
    </section>

    <!-- MANAGE EVENTS -->
    <section class="admin-card" id="manage-events">
        <h2>Manage Events</h2>

        <div class="admin-table-wrapper">
            <table class="admin-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Event</th>
                        <th>Category</th>
                        <th>Date</th>
                        <th>Venue</th>
                        <th>Capacity</th>
                        <th>Registered Students</th>
                        <th>Status</th>
                        <th>Action</th>
                    </tr>
                </thead>

                <tbody>
                <%
                    boolean eventsFound = false;

                    try (Connection con = openConnection();
                         PreparedStatement ps = con.prepareStatement(
                            "SELECT event_id, event_name, category, event_date, " +
                            "venue, max_participants, status " +
                            "FROM events ORDER BY event_date DESC, event_id DESC");
                         ResultSet rs = ps.executeQuery()) {

                        while (rs.next()) {
                            eventsFound = true;
                            int currentEventId = rs.getInt("event_id");
                            int eventRegistrationCount = 0;

                            try (PreparedStatement countPs = con.prepareStatement(
                                    "SELECT COUNT(*) FROM registrations WHERE event_id = ?")) {
                                countPs.setInt(1, currentEventId);

                                try (ResultSet countRs = countPs.executeQuery()) {
                                    if (countRs.next()) {
                                        eventRegistrationCount = countRs.getInt(1);
                                    }
                                }
                            }
                %>
                    <tr>
                        <td><%= currentEventId %></td>

                        <td>
                            <a class="event-name-link"
                               href="eventRegistrations.jsp?eventId=<%= currentEventId %>">
                                <%= esc(rs.getString("event_name")) %>
                            </a>
                        </td>

                        <td><%= esc(rs.getString("category")) %></td>

                        <td>
                            <%
                                java.sql.Date d = rs.getDate("event_date");
                                out.print(d == null ? "—" :
                                    new java.text.SimpleDateFormat("dd MMM yyyy").format(d));
                            %>
                        </td>

                        <td><%= esc(rs.getString("venue")) %></td>

                        <td>
                            <%
                                int capacity = rs.getInt("max_participants");
                                out.print(rs.wasNull() ? "Not specified" : String.valueOf(capacity));
                            %>
                        </td>

                        <td>
                            <a class="registration-count-link"
                               href="eventRegistrations.jsp?eventId=<%= currentEventId %>">
                                <%= eventRegistrationCount %> — View Details
                            </a>
                        </td>

                        <td>
                            <span class="admin-status">
                                <%= esc(rs.getString("status")) %>
                            </span>
                        </td>

                        <td>
                            <a class="admin-edit"
                               href="admin.jsp?editEventId=<%= currentEventId %>#add-event">
                                Edit
                            </a>
<a class="admin-edit"
       href="exportRegistrations.jsp?eventId=<%= currentEventId %>">
        Download CSV
    </a>
                            <form method="post" action="admin.jsp"
                                  onsubmit="return confirm('Delete this event and all its registrations?');">
                                <input type="hidden" name="action" value="deleteEvent">
                                <input type="hidden" name="eventId" value="<%= currentEventId %>">
                                <button type="submit" class="admin-delete">Delete</button>
                            </form>
                        </td>
                    </tr>
                <%
                        }
                    } catch (Exception e) {
                        application.log("Error loading admin event list", e);
                    }

                    if (!eventsFound) {
                %>
                    <tr>
                        <td colspan="9" class="admin-empty">No events found.</td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </section>

    <!-- STUDENT REGISTRATIONS -->
    <section class="admin-card" id="registrations">
        <h2>Student Registrations</h2>

        <div class="admin-table-wrapper">
            <table class="admin-table">
                <thead>
                    <tr>
                        <th>Registration ID</th>
                        <th>Event</th>
                        <th>Student Name</th>
                        <th>Email</th>
                        <th>Department</th>
                        <th>Roll Number</th>
                        <th>Section</th>
                        <th>Year</th>
                        <th>Mobile</th>
                        <th>Status</th>
                    </tr>
                </thead>

                <tbody>
                <%
                    boolean registrationsFound = false;

                    try (Connection con = openConnection();
                         PreparedStatement ps = con.prepareStatement(

"SELECT r.registration_id, r.event_id, r.full_name, r.email, " +
"r.department, r.roll_number, r.section, " +
"r.year_of_study, r.mobile, r.status, e.event_name " +
"FROM registrations r " +
"JOIN events e ON e.event_id = r.event_id " +
"ORDER BY r.registered_at DESC NULLS LAST, " +
"r.registration_id DESC"
);
                         ResultSet rs = ps.executeQuery()) {

                        while (rs.next()) {
                            registrationsFound = true;
                %>
                    <tr>
                        <td><%= rs.getInt("registration_id") %></td>

                        <td>
                            <a class="event-name-link"
                               href="eventRegistrations.jsp?eventId=<%= rs.getInt("event_id") %>">
                                <%= esc(rs.getString("event_name")) %>
                            </a>
                        </td>

                        <td><%= esc(rs.getString("full_name")) %></td>
                        <td><%= esc(rs.getString("email")) %></td>
                        <td><%= esc(rs.getString("department")) %></td>
                        <td><%= esc(rs.getString("roll_number")) %></td>
                        <td><%= esc(rs.getString("section")) %></td>
                        <td><%= esc(rs.getString("year_of_study")) %></td>
                        <td><%= esc(rs.getString("mobile")) %></td>

                        <td>
                            <span class="admin-status">
                                <%= esc(rs.getString("status")) %>
                            </span>
                        </td>
                    </tr>
                <%
                        }
                    } catch (Exception e) {
                        application.log("Error loading student registrations", e);
                    }

                    if (!registrationsFound) {
                %>
                    <tr>
                        <td colspan="10" class="admin-empty">
                            No student registrations found.
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </section>

</main>

<footer class="footer">
    CampusEvents · College Event Management System
</footer>

</body>
</html>
