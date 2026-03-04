<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMP Test • angie.local</title>
    <link rel="stylesheet" href="/assets/style.css"/>
</head>
<body>

<header>
    <div class="logo">AMP • angie.local</div>
    <div class="header-buttons">
        <a href="index.php">Dashboard</a>
        <a href="help.php">Help</a>
        <a href="about.php">About</a>
    </div>
</header>

<div class="main">
    <aside>
        <ul>
            <li><a href="index.php" class="active">Dashboard</a></li>
            <li><a href="#test-network">Test Communication</a></li>
            <li><a href="#docker-network">Docker Networks</a></li>
            <li><a href="help.php">Help</a></li>
            <li><a href="about.php">About</a></li>
        </ul>
    </aside>

    <div class="content">

        <section id="test-network" class="card">
            <h2>Container Network Communication</h2>
            <p>Send a message to another local domain (or test back to angie.local).</p>
            <p>Copy the file <code>talk.php</code> to another local domain (e.g. <code>myproject.local</code>) and update the URL in the form below.</p>

            <form method="post" style="margin: 1.5rem 0;">
                <div style="display: flex; gap: 1rem; align-items: center;">
                    <input type="text" 
                        name="target_url" 
                        placeholder="https://myroject.local/talk.php" 
                        value="https://angie.local/talk.php" 
                        style="flex: 1; padding: 0.8rem; border: 1px solid var(--border); border-radius: 6px; background: hsl(227 25% 18%); color: var(--text); font-family: monospace;">
                    <button type="submit" 
                            name="talk_submit" 
                            style="padding: 0.8rem 1.5rem; background: var(--primary); color: white; border: none; border-radius: 6px; cursor: pointer;">
                        Talk
                    </button>
                </div>
            </form>

            <?php
            if (isset($_POST['talk_submit'])) {
                $url = trim($_POST['target_url'] ?? '');
                if (filter_var($url, FILTER_VALIDATE_URL) === false) {
                    echo '<p style="color: var(--danger);">Invalid URL.</p>';
                } else {
                    $ch = curl_init();
                    curl_setopt_array($ch, [
                        CURLOPT_URL            => $url,
                        CURLOPT_RETURNTRANSFER => true,
                        CURLOPT_SSL_VERIFYPEER => false,   // local self-signed
                        CURLOPT_SSL_VERIFYHOST => false,
                        CURLOPT_TIMEOUT        => 10,
                    ]);

                    $response = curl_exec($ch);
                    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                    $error    = curl_error($ch);
                    curl_close($ch);

                    if ($error) {
                        echo '<p style="color: var(--danger);"><b>Error:</b> ' . htmlspecialchars($error) . '</p>';
                    } else {
                        echo '<p><b>Response from ' . htmlspecialchars($url) . ' (HTTP ' . $httpCode . '):</b></p>';
                        echo '<pre style="background: hsl(227 25% 10%); padding: 1rem; border: 1px solid var(--border); border-radius: 6px; overflow-x: auto; white-space: pre-wrap; word-wrap: break-word;">';
                        echo htmlspecialchars($response ?: '(empty response)');
                        echo '</pre>';
                    }
                }
            }
            ?>
            <br>
            <p><i>You should get a response like "Hello World from angie.local!"</i></p>
        </section>

        <section id="docker-network" class="card">
            <h2>Docker Networking</h2>
            <p>Docker was designed to isolate containers by default. This is intentional for security and portability.
            Each container gets its own:</p>
            <ul>
                <li>Network namespace (separate IP stack)</li>
                <li>Network interfaces</li>
                <li>DNS resolver</li>
            </ul>
            <br/>
            <p>So when Container A tries to call Container B using localhost or a host domain (like homelab.local), it usually fails because:</p>

            <ul>
                <li>localhost inside Container A = Container A itself (not the host or other containers)</li>
                <li>Host domains (.local) are resolved by Windows host DNS, not by Docker’s internal DNS</li>
                <li>Containers are not automatically reachable from each other unless they are on the same Docker network</li>
            </ul>
            <br/> 
            <p>This is the major source of frustration for beginners.</p>
            <h3>How developers solve container isolation</h3>
            <p>Here are the standard, proven ways (from most recommended to least):</p>
            <table>
                <thead>
                    <tr>
                        <th>Method</th>
                        <th>When to use</th>
                        <th>How it works</th>
                        <th>Recommendation</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Docker Compose service name</strong></td>
                        <td>Most common &amp; best</td>
                        <td>Containers resolve each other by service name</td>
                        <td><strong>Best choice</strong></td>
                    </tr>
                    <tr>
                        <td>Custom user-defined network</td>
                        <td>Multiple compose files</td>
                        <td>Explicit network sharing</td>
                        <td>Good</td>
                    </tr>
                    <tr>
                        <td>Host network mode</td>
                        <td>Simple local testing</td>
                        <td>Container shares host network stack</td>
                        <td>Sometimes useful</td>
                    </tr>
                    <tr>
                        <td>Docker DNS + aliases</td>
                        <td>Advanced</td>
                        <td>Manual DNS aliases</td>
                        <td>Rarely needed</td>
                    </tr>
                    <tr>
                        <td>Reverse proxy (Traefik/Nginx)</td>
                        <td>Many domains + external access</td>
                        <td>Single entrypoint for all containers</td>
                        <td>Excellent long-term</td>
                    </tr>
                </tbody>
            </table>
            <br/>
            <h3>Best solution for AMP stack</h3>
            <p>Since you have multiple .local domains and want them to talk to each other, 
            <br/>It uses service names (the Docker way)</p>
            <br/>
            <p>In the Docker Compose file, make sure all the services are on the same network e.g. "angie-network".</p>
            <code>networks:
                    - amp-network
            </code> 
            <p>Then you can call other services by their service name e.g. "call.php" in "talk.php" can call "db:3306" for the database.</p>
            <br>
            <p>Docker isolation is by design.</p>
            <p>The solution is almost always: use Docker service names or proper DNS resolution (.local domains via hosts file or Acrylic).</p>
        </section>
    </div>
</div>

<footer>
    AMP – Angie • MariaDB • PHP • CA-SSL<br>
    <small>© <?= date('Y') ?> gigamaster • <a href="https://github.com/gigamaster/amp" target="_blank">GitHub - AMP</a></small>
</footer>

</body>
</html>