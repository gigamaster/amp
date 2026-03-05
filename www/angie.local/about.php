<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMP About • angie.local</title>
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
            <li><a href="#amp-manager" class="active">AMP Manager</a></li>
            <li><a href="#angie-server">Angie Server</a></li>
            <li><a href="#mariadb">MariaDB</a></li>
            <li><a href="#php-version">PHP Version</a></li>
            <li><a href="#docker">Docker</a></li>
            <li><a href="#utils-tools">Utils/Tools</a></li>
            <li><a href="#github-repo">Github Repo</a></li>
        </ul>
    </aside>

    <div class="content">

        <section id="amp-manager" class="card">
            <h2>AMP Manager</h2>
            <p>The <code>AMP-MANAGER.bat</code> is the central tool for creating, configuring and removing local sites on your machine.</p>
            <p>It handles:</p>
            <ul>
                <li>Angie virtual host configuration</li>
                <li>Local SSL certificate generation (via mkcert)</li>
                <li>Optional scaffolding project folder in <code>D:\amp\www\</code></li>
                <li>Windows hosts file updates (with UAC elevation)</li>
                <li>Basic health checks and cleanup</li>
            </ul>
            <p>Everything is done with readable batch script. You can open, modify and understand every step.</p>
        </section>

        <section id="angie-server" class="card">
            <h2>Angie Server</h2>
            <p>Angie is a high-performance, modern fork of Nginx with enhanced configuration options, better module support and active development.</p>
            <p>In AMP it serves as the web server and reverse proxy:</p>
            <ul>
                <li>Container name: <code>angie</code></li>
                <li>Handles all HTTP/HTTPS traffic</li>
                <li>Passes PHP requests to PHP-FPM</li>
                <li>Loads virtual hosts from <code>/etc/angie/http.d/*.conf</code></li>
            </ul>
            <p>Angie web server is open in public repositories under a <a href="https://github.com/webserver-llc/angie/" target="_blank">BSD-type free license ↗</a></p>
        </section>

        <section id="mariadb" class="card">
            <h2>MariaDB</h2>
            <p>MariaDB is the relational database used in AMP — a drop-in replacement for MySQL with better performance and open-source focus.</p>
            <p>Key facts:</p>
            <ul>
                <li>Container name: <code>db</code></li>
                <li>Exposed port: 3306 (accessible from host)</li>
                <li>Default root password: set in docker-compose or .env</li>
                <li>Default application database: <code>ampdb</code></li>
            </ul>
            <p><a href="https://mariadb.com/docs/general-resources/community/community/faq/licensing-questions/licensing-faq" target="_blank">MariaDB is distributed under the GPL license, version 2 ↗</a></p>
        </section>

        <section id="php-version" class="card">
            <h2>PHP Version</h2>
            <p>AMP uses PHP 8.3 (webdevops/php:8.3 image) with FPM (FastCGI Process Manager)</p>
            <p>for efficient request handling. Enabled by default:</p>
            <ul>
                <li>Container name: <code>php</code></li>
                <li>pdo_mysql, gd, curl, mbstring, openssl, json, xml, zip, intl, fileinfo</li>
                <li>Customization (memory limit, upload size, etc.) is done via <code>D:\amp\config\php.ini</code>.</li>
            </ul>
            <p><a href="https://www.php.net/license/index.php" target="_blank">PHP license is a BSD-style license ↗</a></p>
        </section>

        <section id="docker" class="card">
            <h2>Docker</h2>
            <p>Docker Compose orchestrates the entire AMP stack:</p>
            <ul>
                <li>angie: web server</li>
                <li>php: PHP-FPM processor</li>
                <li>db: MariaDB database</li>
            </ul>
            <p>All important files are bind-mounted from your host.<br/> 
            You edit them directly on Windows, changes are instant.
            </p>
            <p>Basic commands:</p>
            <ul>
                <li>Status: <code>docker compose ps</code></li>
                <li>Logs: <code>docker compose logs -f</code></li>
                <li>Restart: <code>docker compose down && docker compose up -d</code></li>
            </ul>
            <p><a href="https://www.docker.com/legal/docker-subscription-service-agreement/" target="_blank">Docker Desktop is licensed under the Docker Subscription Service Agreement ↗</a></p>
        </section>

        <section id="utils-tools" class="card">
            <h2>Utils/Tools</h2>
            <p>AMP includes a small set of lightweight, open tools:</p>
            <ul>
                <li>mkcert.exe : local SSL certificates (trusted by browsers after install), <a href="https://github.com/FiloSottile/mkcert/blob/master/LICENSE" target="">BSD 3-Clause License ↗</a></li>
                <li>AMP-MANAGER.bat : generates the required configuration for your local environment</li>
                <li>create-shortcut.bat: run this to create a desktop shortcut with an icon</li>
            </ul>
            <br/>
            <p>No heavy frameworks, no telemetry, no vendor lock-in.</p>
        </section>

        <section id="github-repo" class="card">
            <h2>Github Repo</h2>
            <p>The full AMP project is open source and hosted on GitHub:</p>
            <p><a href="https://github.com/gigamaster/amp" style="color: var(--primary); text-decoration: underline;">github.com/gigamaster/amp</a></p>
            <p>You can:</p>
            <ul>
                <li>Fork and modify the stack</li>
                <li>Report issues or suggest improvements</li>
                <li>Contribute new features or documentation</li>
            </ul>    
            <p>Everything is readable and changeable. No proprietary cages. No hidden fees.</p>
            <br/>
<pre>
 MIT License

Copyright (c) 2026 Nuno Luciano - AMP MANAGER - Docker Web Dev Stack

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
</pre>
        </section>

    </div>
</div>

<footer>
    AMP – Angie • MariaDB • PHP • CA-SSL<br>
    <small>© <?= date('Y') ?> gigamaster • <a href="https://github.com/gigamaster/amp" target="_blank">GitHub - AMP</a></small>
</footer>

</body>
</html>