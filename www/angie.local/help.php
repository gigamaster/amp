<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMP Help • angie.local</title>
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
            <li><a href="#getting-started" class="active">Getting Started</a></li>
            <li><a href="#amp-stack">AMP Stack</a></li>
            <li><a href="#ssl-certificates">SSL & Certificates</a></li>
            <li><a href="#setup-domains">Setup .local Domains</a></li>
            <li><a href="#database-settings">Database Settings</a></li>
            <li><a href="#troubleshooting">Troubleshooting</a></li>
            <li><a href="#docker">Docker</a></li>
        </ul>
    </aside>

    <div class="content">

        <section id="getting-started" class="card">
            <h2>Getting Started</h2>
            <p><strong>angie.local</strong> is your control center. It serves the documentation and health-check dashboard.</p>
            <p>If this page isn't loading properly, check the following:</p>
            <ul>
                <li>Docker Desktop is running</li>
                <li>The container named <code>angie</code> is in status <strong>Up</strong></li>
                <li>Run <code>docker compose ps</code> in your project folder to verify</li>
            </ul>
            <p>Access this help page anytime via <code>https://angie.local/help.php</code> or <code>/amp/docs/help.html</code></p>

            <h3>Quick Start</h3>
            <h4>Requirements</h4>
            <ol>
<li><strong>Download:</strong> Clone the repository or download the ZIP and extract it to a folder e.g. <code>D:\amp\</code></li>
<li><strong>Launch Docker:</strong> Open Docker Desktop and ensure the engine is running.</li>
<li><strong>Boot the Stack:</strong> Open a terminal in your project folder and run:</li>
</ul>
<p><code>docker compose up -d</code></p>

<h4>The AMP-MANAGER Setup</h4>

<p>Run <code>AMP-MANAGER.bat</code> triggers UAC elevation dialog to run as Administrator.<br>
This tool allows you to manage your environment, docker, domains and SSL certificates.</p>

<ul>
<li><strong>Install CA:</strong> On the first run, ensure your <strong>Certificate Authority</strong> is properly installed.<br> This allows your browser to trust your local <code>.local</code> sites with green SSL locks.</li>
<li><strong>Add Your First Site:</strong> Select <strong>[N] New Domain</strong> and type <code>angie</code></li>
<li>AMP-MANAGER automatically adds <code>.local</code>, generates your SSL <code>.pem</code> files, and creates the server configuration.</li>
</ul>

<h4>Finalize & Browse</h4>
<ul>
<li><strong>Reload Angie:</strong> For the server to see your new site configuration, from AMP-MANAGER, or restart the container:</li>
<li><strong>Visit the default angie.local:</strong> Open your browser and go to <strong><code>https://angie.local</code></strong></li>
<li>This is your <strong>Control Center</strong> for documentation, health checks, and status monitoring.</li>
</ul>

        </section>

        <section id="amp-stack" class="card">
            <h2>AMP Stack</h2>
            <p>Angie is a modern fork of Nginx with enhanced features, better performance tuning options, and active maintenance.</p>
            <p>In this AMP stack:</p>
            <ul>
                <li>Angie handles all HTTP/HTTPS traffic</li>
                <li>PHP-FPM processes dynamic content</li>
                <li>All configuration files live on your host: <code>D:\amp\config\angie-sites\*.conf</code></li>
            </ul>
            <p>More detailed setup information is available on the official websites:</p>
            <p><a href="https://en.angie.software/" target="_blank">Angie, a free fork of nginx, a powerful and scalable web server ↗</a></p>
            <p><a href="https://en.angie.software/angie/docs/installation/external-modules/" target="_blank">Angie srver external modules ↗</a></p>
            <p><a href="https://mariadb.org/" target="_blank"> MariaDB Server: the innovative open source database ↗</a></p>
            <p><a href="https://www.php.net/" target="_blank">PHP: the popular general-purpose scripting language  ↗</a></p>
            <p><a href="https://github.com/FiloSottile/mkcert" target="_blank">Mkcert: zero-config tool to make locally trusted certificates ↗</a></p>
        </section>

        <section id="ssl-certificates" class="card">
            <h2>SSL & Certificates</h2>
            <p>We use <strong>mkcert</strong> to create locally trusted certificates.</p>
            <p>If browsers show a red warning or "Not Secure":</p>
            <ul>
                <li>Run Option 9 in amp-manager.bat to re-trust the AMP-Manager Root Authority</li>
                <li>Or manually run <code>mkcert -install</code> in your command prompt (as Administrator the first time)</li>
                <li>After trusting, restart your browser</li>
            </ul>
            <p>All certificates are stored in <code>D:\amp\config\certs\</code></p>
        </section>

        <section id="setup-domains" class="card">
            <h2>Setup .local Domains</h2>
            <p>To add a new local site:</p>
            <ol>
                <li>Create your project folder inside <code>D:\amp\www\project.local\</code></li>
                <li>Run AMP-MANAGER to generate the server conf. file <code>D:\amp\config\angie-sites\project.local.conf</code></li>
                <li>And create the required domain entry and <code>.pem</code> certificate:
                    <ul>
                        <li>Generate SSL certificate (mkcert)</li>
                        <li>Add entry to Windows hosts file (127.0.0.1 yourproject.local)</li>
                        <li>Reload Angie</li>
                    </ul>
                </li>
                <li>Ensure your <code>.conf</code> file has the correct <code>server_name project.local;</code> and <code>root /www/project.local/public;</code></li>
            </ol>
            <p>If you edit angie.local.conf avoid editing the <code>DASHBOARD & API</code> required for server <code>/status/</code></p>
            <br>
            <div id="code-lab" data-height="330"></div>

<script type="module">
import { createPlayground } from 'https://cdn.jsdelivr.net/npm/livecodes@0.13.0';

createPlayground('#code-lab', {
    params: {
    language: 'markdown',
    view: 'markdown',
    mode: 'codeblock',
    theme: 'dark',
    markdown: '```nginx\n' +
'    # DASHBOARD & API\n' +
'    # Route calls to the API for the dashboard\n' +
'    location /status/api/ {\n' +
'        api /status/;\n' +
'        allow all;\n' +
'    }\n' +
'\n' +
'    # Serve the dashboard static files\n' +
'    location /status/ {\n' +
'        alias /usr/share/angie/html/status/;\n' +
'        index index.html;\n' +
'    }\n' +
'\n' +
'    # Protect error pages\n' +
'}\n' +
'```',

    }
});
</script>
        </section>

        <section id="database-settings" class="card">
            <h2>Database Settings</h2>
            <p>Default credentials (change in production or via docker-compose):</p>
            <ul>
                <li>Host: <code>db</code> (MariaDB container name)</li>
                <li>Root user: <code>root</code></li>
                <li>Root password: set in docker-compose or .env</li>
                <li>Application user: <code>ampuser</code></li>
                <li>Default database: <code>ampdb</code></li>
            </ul>
            <p>To create a new database:</p>
            <ol>
                <li>Open phpMyAdmin (via Database Admin link) or any MySQL client</li>
                <li>Login as root</li>
                <li>Create new database → assign privileges to ampuser if needed</li>
            </ol>
            <div class="tip">
                <p><strong>Tip</strong></p>
                <p>Manage databases with root credentials and create dedicated users per project.</p>
            </div>
        </section>

        <section id="troubleshooting" class="card">
            <h2>Troubleshooting</h2>
            <ul>
                <li><strong>Port 80/443 conflict</strong>: Close Skype, IIS, Apache, or any other web server using these ports.</li>
                <li><strong>Site not loading</strong>: Check Docker logs: <code>docker logs angie</code></li>
                <li><strong>SSL warning</strong>: Re-trust mkcert root CA (see SSL section)</li>
                <li><strong>Domain not resolving</strong>: Verify entry in <code>C:\Windows\System32\drivers\etc\hosts</code></li>
                <li><strong>PHP errors</strong>: Check logs in <code>D:\amp\logs\php\</code></li>
            </ul>
            <p>You can use the built-in PHP server for debugging, if you're having trouble with a specific script,<br>
                e.g. a syntax error that is hard to find in Docker logs, just run this in the project folder:</p>
            <p><code>php -S localhost:8000</code></p>
            <ul>
                <li>You get instant feedback: Errors are printed directly to the terminal window in real-time.</li>
                <li>Isolation: It removes Docker, Angie, and SSL from the equation.<br>
                    <i>If it works here but fails in the stack, the problem is in the Server Config, not the PHP Code.</i></li>
            </ul>
            <p>While great for a quick test, php -S has three major limitations:</p>
            <ul>
                <li>The built-in server ignores all your custom location blocks and rewrite rules.</li>
                <li>Single-Threaded: It can only handle one request at a time.</li>
                <li>No HTTPS: It runs on http://, so features requiring a Secure Context (like some modern JS APIs) will fail.</li>
            </ul>
            <div class="tip">
                <p><strong>Tip</strong></p>
                <p>Use php -S only if you need to see raw PHP errors instantly without checking the Docker logs.</p>
            </div>
        </section>

        <section id="docker" class="card">
            <h2>Docker</h2>
            <p>Common daily commands:</p>
            <ul>
                <li>Check status: <code>docker compose ps</code></li>
                <li>View logs: <code>docker compose logs -f angie</code> or <code>docker logs angie</code></li>
                <li>Restart stack: <code>docker compose down && docker compose up -d</code></li>
                <li>Enter container: <code>docker compose exec angie sh</code> or <code>docker compose exec php sh</code></li>
                <li>Reload Angie without restart: <code>docker compose exec angie angie -s reload</code></li>
            </ul>
            <div class="tip">
                <p><strong>Tip</strong></p>
                <p>Container crash? Look for syntax errors in config files or missing mounts in <code>docker-compose.yml</code>.</p>
            </div>
        </section>

    </div>
</div>

<footer>
    AMP – Angie • MariaDB • PHP • CA-SSL<br>
    <small>© <?= date('Y') ?> gigamaster • <a href="https://github.com/gigamaster/amp" target="_blank">GitHub - AMP</a></small>
</footer>

</body>
</html>