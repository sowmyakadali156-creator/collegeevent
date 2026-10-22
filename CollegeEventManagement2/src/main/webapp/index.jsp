
<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>Campus Events</title>
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>

    <%@ include file="includes/header.jspf" %>

    <section class="hero">
        <h1>Discover. Participate. Make memories.</h1>

        <p>
            Your campus, your community, your next big experience.
            Explore hackathons, workshops, paper presentations,
            project expos, cultural programmes and more.
        </p>

        <a class="btn" href="events.jsp">Explore Events</a>
    </section>

    <section class="section">
        <h2>Find your next campus experience</h2>

        <p class="muted">
            Learn new skills, meet collaborators, and show your talent
            at college events.
        </p>

        <div class="grid">

            <!-- Hackathon card -->
            <div class="event-card">
                <img
                    src="https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=900"
                    alt="Hackathon">

                <div class="event-body">
                    <span class="tag">TECHNICAL</span>
                    <h3>Hackathons</h3>
                    <p class="muted">
                        Build ideas into working prototypes with your team.
                    </p>
                </div>
            </div>

            <!-- Paper presentation card -->
            <div class="event-card">
                <img
                    src="https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=900"
                    alt="Presentation">

                <div class="event-body">
                    <span class="tag">LEARNING</span>
                    <h3>Paper Presentations</h3>
                    <p class="muted">
                        Share your research and learn from others.
                    </p>
                </div>
            </div>

            <!-- Cultural event card -->
            <div class="event-card">
                <img
                    src="https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=900"
                    alt="Cultural event">

                <div class="event-body">
                    <span class="tag">CULTURE</span>
                    <h3>Cultural Events</h3>
                    <p class="muted">
                        Celebrate creativity, music, dance and campus life.
                    </p>
                </div>
            </div>

        </div>
    </section>

    <footer class="footer">
        College Event Management System
    </footer>

</body>
</html>
