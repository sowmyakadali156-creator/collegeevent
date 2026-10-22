
<%@ page contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.Locale" %>
<%@ include file="includes/db.jspf" %>

<%
String error = null;

if ("POST".equalsIgnoreCase(request.getMethod())) {

    String email = request.getParameter("email");
    String password = request.getParameter("password");

    if (email == null || password == null ||
        email.trim().isEmpty() || password.isEmpty()) {

        error = "Please enter your email and password.";

    } else {

        try (Connection con = openConnection();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT user_id, full_name, role " +
                 "FROM users " +
                 "WHERE LOWER(email) = LOWER(?) " +
                 "AND password = ?"
             )) {

            ps.setString(1, email.trim());
            ps.setString(2, password);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {

                    int userId = rs.getInt("user_id");
                    String userName = rs.getString("full_name");
                    String role = rs.getString("role");

                    role = role == null ? "" :
                           role.trim().toUpperCase(Locale.ROOT);

                    if ("ADMIN".equals(role) ||
                        "STUDENT".equals(role)) {

                        session.invalidate();

                        javax.servlet.http.HttpSession newSession =
                            request.getSession(true);

                        newSession.setAttribute("userId", userId);
                        newSession.setAttribute("userName", userName);
                        newSession.setAttribute("role", role);
                        newSession.setMaxInactiveInterval(30 * 60);
                        if ("ADMIN".equals(role)) {
                            response.sendRedirect("admin.jsp");
                        } else {
                            response.sendRedirect("index.jsp");
                        }

                        return;

                    } else {
                        error = "Your account has an invalid role.";
                    }

                } else {
                    error = "Invalid email or password.";
                }
            }

        } catch (Exception e) {
            application.log("Login error", e);
            error = "Unable to log in. Please check the database connection.";
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>Login - College Event Management</title>

    <link rel="stylesheet" href="assets/style.css">
</head>

<body>

<%@ include file="includes/header.jspf" %>

<main class="auth-container">
    <section class="auth-card">

        <h1>Login</h1>
        <p>Sign in to your College Events account.</p>

        <% if (request.getParameter("registered") != null) { %>
            <p class="success">
                Registration successful. Please log in.
            </p>
        <% } %>

        <% if (error != null) { %>
            <p class="error"><%= esc(error) %></p>
        <% } %>

        <form method="post" action="login.jsp">

            <div class="form-group">
                <label for="email">Email</label>
                <input type="email"
                       id="email"
                       name="email"
                       value="<%= esc(request.getParameter("email") == null
                                  ? "" : request.getParameter("email")) %>"
                       autocomplete="username"
                       required>
            </div>

            <div class="form-group">
                <label for="password">Password</label>
                <input type="password"
                       id="password"
                       name="password"
                       autocomplete="current-password"
                       required>
            </div>

            <button type="submit" class="btn">Login</button>

        </form>

        <p>
            Don't have an account?
            <a href="register.jsp">Sign Up</a>
        </p>

    </section>
</main>

<footer class="footer">
    College Event Management System
</footer>

</body>
</html>
