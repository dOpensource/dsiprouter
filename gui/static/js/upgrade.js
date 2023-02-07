;

function getUpgradeInfo() {

    $('#upgrade_form').hide();
    $('#upgrade_output_row').show();

    $.get("/upgrade-status", function (response) {
        $("#upgrade_output").text(response);
        $('#page_bottom')[0].scrollIntoView();
        // $(document).scrollTop($(document).height());
    });
}


(function (window, document) {
    'use strict';


    $(document).ready(function () {

        $('#btnShowLog').click(function () {
            getUpgradeInfo()
        });

        $("#upgrade_form").submit(function (e) {

            var theInterval = setInterval(getUpgradeInfo, 1000);

            e.preventDefault();
            var formData = $(this).serialize();

            $.ajax({
                type: "POST",
                url: "/upgrade",
                async: true,
                data: formData,
                success: function (response) {
                    console.info(response);
                    clearInterval(theInterval);
                    getUpgradeInfo();
                },
                error: function (error) {
                    console.error(error);
                    clearInterval(theInterval);
                }
            });


        });

    });

})(window, document);
