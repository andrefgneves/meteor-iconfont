@font-face {
    font-family: '<%= fontName %>';
    <% _.forEach(fontSrcs, function(src) { %>
    src: <%= src %>;
    <% }); %>
    font-weight: normal;
    font-style: normal;
}

<%= classNames %> {
    font-family: '<%= fontName %>';
    -moz-osx-font-smoothing: grayscale;
    -webkit-font-smoothing: antialiased;
    font-style: normal;
    font-variant: normal;
    font-weight: normal;
    line-height: 1;
    speak: none;
    text-transform: none;
}

<% _.forEach(glyphCodepointMap, function(codepoint, name) { %>
.<%= classPrefix %><%= name %>:before {
    content: '\<%= codepoint %>';
}
<% }); %>
