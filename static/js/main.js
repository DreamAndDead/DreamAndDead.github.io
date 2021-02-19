$(document).ready(function() {
    $("body").prognroll({
        height: 3,
        color: "#111",
        custom: false
    });

    var sjs = SimpleJekyllSearch({
        searchInput: document.getElementById('search-input'),
        resultsContainer: document.getElementById('results-container'),
        json: '/search.json'
    });
});
