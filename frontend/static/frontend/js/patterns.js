$('.template-item').on('click', function (event) {
    console.log(this.dataset.template);

    var name = "";
    var pattern = "";

    switch (this.dataset.template) {
    case "all":
        name = "Alles";
        pattern = ".*";
        break;
    case "spez":
        name = "Spez.";
        pattern = "^Spez";
        break
    case "fu":
        name = "Führung";
        pattern = "^Fu";
        break;
    }

    $("#pattern-name").val(name);
    $("#pattern-pattern").val(pattern);
});
