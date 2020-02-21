<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Sydnod | CI</title>

        <link href="https://fonts.googleapis.com/css?family=Roboto&display=swap" rel="stylesheet">

        <style>
        html,
        body {
            padding: 0;
            margin: 0;

            font-family: 'Roboto', sans-serif;
            height: 100%;
            overflow: hidden;

            background-color: #0A1128;
            color: #fff;
        }

        p {
            margin: 0;
            padding: 0;
        }
        
        span {
            display: block;
            padding-bottom: 4px;
            font-size: 19px;
            font-weight: bold;
        }

        .outer-div
        {
            display: table;
            position: absolute;
            height: 100%;
            width: 100%;
        }
        .mid-div
        {
            display: table-cell;
            vertical-align: middle;
        }
        .center-div
        {
            margin: 0 auto;
            width: 300px;
            height: 100px;
            border-radius: 3px;

            text-align: center;
        }

        div.logo {
            padding-bottom: 10px;
        }

        div.logo img {
            width: 260px;
            height: 58px;
        }

        #bottom-right {
            position: absolute;
            bottom: 0;
            right: 0;
        }

        #bottom-right img {
            width: 32px;
            height: 32px;

            padding: 20px;
        }
        </style>
    </head>
    <body>
        <div class="outer-div">
            <div class="mid-div">
                <div class="center-div">
                    <div class="logo">
                        <a href="https://sydnod.com">
                            <img src="static/sydnod-logo.png" alt="Sydnod" />
                        </a>
                    </div>
        
                    <div>
                        <span>Continuous Integration</span>
                    </div>

                    <div>
                        Build: <?php echo getenv('CI_COMMIT_SHA_SHORT'); ?>
                    </div>
                </div>
            </div>
        </div>
        <div id="bottom-right">
            <a href="https://www.github.com/sydnod/ci">
                <img src="static/github-logo.png" alt="GitHub repository" />
            </a>
    </body>
</html>
