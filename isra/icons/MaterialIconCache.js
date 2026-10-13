.pragma library

var _paths = ({});

function get(file) {
    return _paths[file];
}

function set(file, svg) {
    const paths = [];
    const regex = /d="([^"]+)"/g;
    let match;
    while ((match = regex.exec(svg)) !== null)
        paths.push(match[1]);
    _paths[file] = paths;
    return paths;
}
