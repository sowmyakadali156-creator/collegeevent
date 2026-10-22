
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="includes/db.jspf" %>

<%
String error = null;

if ("POST".equalsIgnoreCase(request.getMethod())) {

    String name = request.getParameter("fullName");
    String email = request.getParameter("email");
    String password = request.getParameter("password");

    if (name == null || email == null || password == null ||
        name.trim().isEmpty() || email.trim().isEmpty() ||
        password.length() < 6) {

        error = "Enter all details. Password must have at least 6 characters.";

    } else {

        Connection con = null;
        PreparedStatement ps = null;

        try {
            con = openConnection();

            ps = con.prepareStatement(
                "INSERT INTO USERS (FULL_NAME, EMAIL, PASSWORD, ROLE) " +
                "VALUES (?, ?, ?, 'STUDENT')"
            );

            ps.setString(1, name.trim());
            ps.setString(2, email.trim().toLowerCase());
            ps.setString(3, password);

            ps.executeUpdate();

            response.sendRedirect("login.jsp?registered=1");
            return;

        } catch (SQLException e) {

            application.log("Student registration SQL error", e);

            if (e.getErrorCode() == 1) {
                error = "That email is already registered.";
            } else {
                error = "Registration failed. Please check the database and try again.";
            }

        } catch (Exception e) {

            application.log("Student registration error", e);
            error = "Database connection failed. Please try again.";

        } finally {

            if (ps != null) {
                try {
                    ps.close();
                } catch (Exception ignored) {
                }
            }

            if (con != null) {
                try {
                    con.close();
                } catch (Exception ignored) {
                }
            }
        }
    }
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Student Registration | CampusEvents</title>

    <link rel="stylesheet" href="assets/style.css">
</head>

<body>

    <%@ include file="includes/header.jspf" %>

    <div class="form-card">

        <h1>Create Student Account</h1>

        <p class="muted">
            Join college events and register online.
        </p>

        <% if ("1".equals(request.getParameter("registered"))) { %>
            <div class="alert">
                Registration successful! Please log in.
            </div>
        <% } %>

        <% if (error != null) { %>
            <div class="alert">
                <%= esc(error) %>
            </div>
        <% } %>

        <form method="post" action="register.jsp">

            <div class="field">
                <label for="fullName">Full Name</label>

                <input
                    type="text"
                    id="fullName"
                    name="fullName"
                    maxlength="100"
                    autocomplete="name"
                    required>
            </div>

            <div class="field">
                <label for="email">Email</label>

                <input
                    type="email"
                    id="email"
                    name="email"
                    maxlength="150"
                    autocomplete="email"
                    required>
            </div>

            <div class="field">
                <label for="password">
                    Password (minimum 6 characters)
                </label>

                <input
                    type="password"
                    id="password"
                    name="password"
                    minlength="6"
                    autocomplete="new-password"
                    required>
            </div>

            <button type="submit" class="btn">
                Create Account
            </button>

        </form>

        <p>
            Already registered?
            <a href="login.jsp">Login</a>
        </p>

    </div>

    <footer class="footer">
        College Event Management System
    </footer>

</body>
</html>
