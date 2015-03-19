<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>Genghis &mdash; {{ status }}: {{ message }}</title>
    <link rel="shortcut icon" type="image/png" href="<%= favicon %>">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="//fonts.googleapis.com/css?family=Rokkitt:400,700|Source+Code+Pro">
    <link rel="stylesheet" href="{{ base_url }}/css/style.css?v={{ genghis_version }}">
  </head>
  <body>
    <header class="navbar navbar-default navbar-fixed-top">
      <div class="container">
        <div class="navbar-header"><a class="navbar-brand" href="{{ base_url }}/">Genghis</a></div>
        <nav></nav>
      </div>
    </header>

    <header class="masthead epic error">
      <div class="container">
        <h1>{{ status }}: {{ message }}</h1>
        <p>
          If you think you've reached this message in error, please press <strong>0</strong> to speak with
          an operator. Otherwise, hang up and try again.
        </p>
      </div>
    </header>

    <footer class="container" id="footer">
      <p><a href="http://genghisapp.com">Genghis</a>, by <a href="http://justinhileman.info">Justin Hileman</a>.</p>
    </footer>
  </body>
</html>
