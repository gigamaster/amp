<?php
    // AMP-MANAGER: Dashboard - angie.local

    $importantExtensions = ['pdo_mysql', 'gd', 'curl', 'mbstring', 'openssl', 'json', 'xml', 'zip', 'intl', 'fileinfo'];

    $phpLimits = [
        'memory_limit'       => ini_get('memory_limit'),
        'max_execution_time' => ini_get('max_execution_time') . ' seconds',
        'upload_max_filesize'=> ini_get('upload_max_filesize'),
        'post_max_size'      => ini_get('post_max_size'),
        'max_input_vars'     => ini_get('max_input_vars'),
    ];

    // SERVER_SOFTWARE to detect Angie version
    if (isset($_SERVER['SERVER_SOFTWARE'])) {
        $serverSoftware = $_SERVER['SERVER_SOFTWARE'];
        $angie_version = "Server software: " . $serverSoftware;

        // Extract Angie version if present
        if (stripos($serverSoftware, 'Angie') !== false) {
            preg_match('/Angie\/([\d\.]+)/i', $serverSoftware, $matches);
            if (!empty($matches[1])) {
                $angie_version .= "\nAngie server version: " . $matches[1];
            } else {
                $angie_version .= "\nAngie server detected, but version not found.";
            }
        } else {
            $angie_version .= "\nNot running on Angie server.";
        }
    } else {
        $angie_version = 'SERVER_SOFTWARE variable not available; run: docker compose exec angie angie -v';
    }

    // AMP local domains
    function getDomains() {
        $dir = '/etc/angie/http.d/';
        if (!is_dir($dir) || !is_readable($dir)) return ['total' => 0, 'list' => [], 'error' => 'Config dir not accessible'];
        $files = glob($dir . '*.conf');
        $domains = [];
        foreach ($files ?: [] as $file) {
            $filename = basename($file);
            if (preg_match('/^(.+\.local)\.conf$/i', $filename, $m)) $domains[] = $m[1];
        }
        sort($domains, SORT_NATURAL | SORT_FLAG_CASE);
        return ['total' => count($domains), 'list' => $domains, 'error' => ''];
    }

    $domainsInfo = getDomains();

    // Database config & test logic
    // default values, override by form POST
    $db_host = 'db';
    $db_port = 3306;

    $root_user = $_POST['root_user'] ?? 'root';
    $root_pass = $_POST['root_pass'] ?? 'rootpass123';

    $app_user = $_POST['app_user'] ?? 'ampuser';
    $app_pass = $_POST['app_pass'] ?? 'ampass456';
    $app_db   = $_POST['app_db'] ?? 'ampdb';

    // Initialize variables
    $mariadb_version      = null;
    $mariadb_connect_msg  = '';
    $status_class         = 'muted';
    $render_msg           = '<p><strong>Status:</strong> <span class="muted">Not tested yet</span></p>';
    $render_db_list       = '';

    // Helper
    // try connection, return result
    function try_conn($host, $port, $user, $pass, $db = '') {
        $conn = @new mysqli($host, $user, $pass, $db, $port);
        if ($conn->connect_error) {
            return ['ok' => false, 'msg' => $conn->connect_error, 'conn' => null];
        }
        return ['ok' => true, 'msg' => 'Connected', 'conn' => $conn];
    }

    // Connection test for Core card
    $root_res = try_conn($db_host, $db_port, $root_user, $root_pass);
    if ($root_res['ok']) {
        $root_conn = $root_res['conn'];

        // Get MariaDB version
        $res = $root_conn->query('SELECT VERSION() AS v');
        $mariadb_version = $res ? $res->fetch_assoc()['v'] ?? 'Connected' : 'Query failed';

        // Default status, app user not tested
        $status_class = 'success';
        $mariadb_connect_msg = 'Connected via root';

        $root_conn->close();
    } else {
        $mariadb_version = 'Not reachable';
        $mariadb_connect_msg = 'Connection failed: ' . $root_res['msg'];
        $status_class = 'error';
    }

    // Prepare Core card output
    $db_version_status = '<span class="' . $status_class . '">' . htmlspecialchars($mariadb_version) . '</span>';
    if (!empty($mariadb_connect_msg)) {
        $db_version_status .= ' <small>(' . htmlspecialchars($mariadb_connect_msg) . ')</small>';
    }
    if ($status_class === 'success') {
        $db_version_status .= ' <small style="color:var(--green);">Ready</small>';
    } else {
        $db_version_status .= ' <small style="color:var(--red);">Check Docker service & container "db" is Up</small>';
    }

    // FORM SUBMIT: TEST & CREATE DATABASE
    if (isset($_POST['test_db'])) {
        $create = isset($_POST['create_db']) && $_POST['create_db'] === '1';

        $msg = '';
        $msg_user = '';
        $db_list = [];

        // Root connection for create, list, grant
        $root_res = try_conn($db_host, $db_port, $root_user, $root_pass);
        if ($root_res['ok']) {
            $root_conn = $root_res['conn'];

            // List all databases
            $res = $root_conn->query("SHOW DATABASES");
            while ($row = $res->fetch_assoc()) {
                $db_list[] = $row['Database'];
            }

            // Create DB with user and grant using root
            if ($create && $app_db) {
                $root_conn->query("CREATE DATABASE IF NOT EXISTS `$app_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
                $root_conn->query("CREATE USER IF NOT EXISTS `$app_user`@'%' IDENTIFIED BY '$app_pass'");
                $root_conn->query("GRANT ALL PRIVILEGES ON `$app_db`.* TO `$app_user`@'%'");
                $root_conn->query("FLUSH PRIVILEGES");
                $msg .= "Database '$app_db' created + privileges granted. ";
            }

            // Test app user connection
            $app_res = try_conn($db_host, $db_port, $app_user, $app_pass, $app_db);
            if ($app_res['ok']) {
                $status_class = 'success';
                $msg_user = "App user connected !";
            } else {
                $status_class = 'error';
                $msg_user = "App user failed: " . $app_res['msg'];
            }

            $root_conn->close();
        } else {
            $status_class = 'error';
            $msg = "Root connection failed: " . $root_res['msg'];
        }

        // Prepare variables for form card layout
        $render_msg = "<p><strong>Status:</strong> <span class=\"$status_class\">" . htmlspecialchars($msg) . "</span></p>";
        $render_msg .= "<p><strong>User Test:</strong> <span class=\"$status_class\">" . htmlspecialchars($msg_user) . "</span></p>";
        $render_msg .= "<p><strong>Version:</strong> " . htmlspecialchars($mariadb_version) . "</p>";

        if ($db_list) {
            $render_db_list = "<p><strong>Existing databases:</strong></p><ul class=\"db-list\">";
            foreach ($db_list as $dbn) {
                $hl = ($dbn === $app_db) ? ' style="color:var(--primary);font-weight:bold;"' : '';
                $render_db_list .= "<li$hl>" . htmlspecialchars($dbn) . "</li>";
            }
            $render_db_list .= "</ul>";
            $render_db_list .= "<p style=\"color:var(--muted);\">Pick a different name if yours is listed.</p>";
        } else {
            $render_db_list = "<p style=\"color:var(--muted);\">No databases found (or connection issue).</p>";
        }
    }
?>
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AMP-MANAGER Dashboard • angie.local</title>
    <meta name="description" content="AMP-MANAGER Dashboard">
    <link rel="shortcut icon" href="/favicon/favicon-16-32.ico">
    <link rel="apple-touch-icon-precomposed" type="image/png" href="/favicon/favicon-152.png">
    <link rel="stylesheet" href="/assets/style.css"/>
    <!-- <script src="/assets/scripts.js"></script> -->
</head>
<body>
<div class="hero">
    <div>
        <a href="#welcome-app" class="scroll-arrow" title="Discover more">
        <div class="hero-logo">AMP</div>
        <p style="font-size:1.75rem; opacity:0.9; margin-top:1rem;">
            Angie • MariaDB • PHP • SSL
        </p>
        <p style="font-size:1.25rem; opacity:0.7; margin-top:0.5rem;">
            Local Development Stack
        </p>
    </div>
    <div class="hero-arrow">
        ↓
    </div>
    </a>
</div>

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
            <li><a href="#domains">Domains (<?= $domainsInfo['total'] ?>)</a></li>
            <li><a href="#core">Core Components</a></li>
            <li><a href="#db">Database Connection</a></li>
            <li><a href="#extensions">PHP Extensions</a></li>
            <li><a href="#limits">PHP Limits</a></li>
            <li><a href="#credential">Credentials</a></li>
            <li><a href="#custom">Customization</a></li>
        </ul>
    </aside>

    <div class="content">

        <section id="welcome-app" class="card">
            <h2>Welcome to AMP</h2>
            <p>Your local development stack is ready.</p>
            <br/>
            <P><a href="/status/index.html" target="_blank">Real-time server status ↗</a></P>
        </section>

        <section id="domains" class="card">
            <h2>Domains (<?= $domainsInfo['total'] ?> total)</h2>
            <?php if ($domainsInfo['error']): ?>
                <p style="color: var(--red);"><?= htmlspecialchars($domainsInfo['error']) ?></p>
            <?php elseif ($domainsInfo['total'] === 0): ?>
                <p>No .local domains found</p>
            <?php else: ?>
                <div class="domains-list">
                    <?php foreach ($domainsInfo['list'] as $domain): ?>
                        <div class="domain-tag"><a href="http://<?= htmlspecialchars($domain) ?>" target="_blank"><?= htmlspecialchars($domain) ?></a></div>
                    <?php endforeach; ?>
                </div>
            <?php endif; ?>
        </section>

        <section id="core" class="card">
            <h2>Core Components</h2>
            <table>
                <tr><th>Component</th><th>Version</th></tr>
                <tr><td>Angie Server</td><td><?= $angie_version ?></td></tr>
                <tr><td>PHP</td><td><?= phpversion() ?></td></tr>
                <tr><td>MariaDB</td><td><?php echo $db_version_status; ?></td>
            </tr>
            </table>
        </section>

        <section id="db" class="card">
            <h2>Database Connection</h2>
            <p>Server: <code>  db  </code> </p>
            <table>
                <tr><th>Root</th><th>User</th></tr>
                <tr><td>Database: <code>ampdb</code></td><td>Database: <code>ampdb</code></td></tr>
                <tr><td>User: <code>root</code></td><td>User: <code>ampuser</code></td></tr>
                <tr><td>Pass: <code>rootpass123</code></td><td>Pass: <code>ampass456</code></td></tr>     
            </table>
        </section>

        <section id="db-config" class="card">
            <h2>Database Configuration</h2>

            <form method="post">
                <table style="width:100%; margin-bottom:1.5rem;">
                    <tr>
                        <th>Root (admin)</th>
                        <th>App User</th>
                    </tr>
                    <tr>
                        <td>
                            User: <input type="text" name="root_user" value="<?= htmlspecialchars($_POST['root_user'] ?? 'root') ?>" required>
                            Password: <input type="password" name="root_pass" value="<?= htmlspecialchars($_POST['root_pass'] ?? 'rootpass123') ?>" required>
                        </td>
                        <td>
                            User: <input type="text" name="app_user" value="<?= htmlspecialchars($_POST['app_user'] ?? 'ampuser') ?>" required>
                            Password: <input type="password" name="app_pass" value="<?= htmlspecialchars($_POST['app_pass'] ?? 'ampass456') ?>" required>
                            Database: <input type="text" name="app_db" value="<?= htmlspecialchars($_POST['app_db'] ?? 'ampdb') ?>" required>
                        </td>
                    </tr>
                </table>

                <label class="custom-checkbox">
                    <input type="checkbox" name="create_db" value="1" <?= isset($_POST['create_db']) ? 'checked' : '' ?>>
                    Create database if it doesn't exist and grant privileges to app user
                </label>

                <button type="submit" name="test_db">Test Connection & Create (if checked)</button>
            </form>

            <?php if (isset($_POST['test_db'])): ?>
                <div class="db-result">
                    <?php echo $render_msg; ?>
                    <?php echo $render_db_list; ?>
                </div>
            <?php endif; ?>
            
        </section>


        <section id="extensions" class="card">
            <h2>PHP Extensions (commonly used)</h2>
            <ul style="columns: 3; list-style:none; padding:0; column-gap: 2rem;">
                <?php foreach ($importantExtensions as $ext): ?>
                    <li style="margin-bottom:0.6rem;">
                        <?= $ext ?>: 
                        <strong class="<?= extension_loaded($ext) ? 'status-good' : 'status-bad' ?>">
                            <?= extension_loaded($ext) ? 'enabled' : 'missing' ?>
                        </strong>
                    </li>
                <?php endforeach; ?>
            </ul>
        </section>

        <section id="limits" class="card">
            <h2>PHP Limits</h2>
            <table>
                <tr><th>Setting</th><th>Value</th></tr>
                <?php foreach ($phpLimits as $key => $val): ?>
                    <tr><td><?= htmlspecialchars($key) ?></td><td><?= htmlspecialchars($val) ?></td></tr>
                <?php endforeach; ?>
            </table>
        </section>

        <section id="credential" class="card">
            <h2>Credentials</h2>
            <p>This is a local development stack.</p>
            <ul style="margin:1rem 0; padding-left:1.5rem; line-height:1.6;">
                <li>No passwords are stored by AMP-Manager.</li>
                <li>Edit <code>docker-compose.yml</code> or <code>.env</code> for changes</li>
                <li>SSL: self-signed via mkcert (trusted locally after install CA)</li>
                <li>All configuration files are on host: <code>[C:][D:]or[USB]\amp\config\...</code></li>
            </ul>
        </section>

        <section id="custom" class="card">
            <h2>Customization</h2>
            <p>This is Open Source.</p>
            <p>This stack is intentionally kept small and readable.<br/>
            You can open every .bat file, every .conf file, every docker-compose.yml.<br/>
            Change them. Break them. Fix them.<br/>
            That is how you really learn.
            </p>
            <br/>
            <p>To add more PHP extensions, edit the Dockerfile and rebuild the image.</p>
            <p>To add more services (Redis, Mailhog, etc), edit docker-compose.yml and add configs.</p>
            <p>To contribute improvements, submit a PR on GitHub: <a href="https://github.com/gigamaster/amp" target="_blank">https://github.com/gigamaster/amp</a></p>
        </section>

    </div>
</div>

<footer>
    AMP • Angie • MariaDB • PHP • CA-SSL<br>
    <small>© <?= date('Y') ?> gigamaster • <a href="https://github.com/gigamaster/amp" target="_blank">GitHub - AMP</a></small>
</footer>
<script>
// header background change when scrolled
window.addEventListener('scroll', () => {
    document.querySelector('header').classList.toggle('scrolled', window.scrollY > 50);
});
</script>
</body>
</html>