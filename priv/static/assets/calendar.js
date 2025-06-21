function kalEl(settings = {}) {
    const pad = (val) => (val + 1).toString().padStart(2, '0');
    const render = (date, locale) => {
        const month = date.getMonth();
        const year = date.getFullYear();
        const numOfDays = new Date(year, month + 1, 0).getDate();
        const renderToday = (year === config.today.year) && (month === config.today.month);

        return `<kal-el data-firstday="${config.info.firstDay}">
            <time datetime="${year}-${(pad(month))}">${new Intl.DateTimeFormat(locale, { month: 'long'}).format(date)} <i>${year}</i></time>
            <ul>${weekdays(config.info.firstDay,locale).map(name => `<li><abbr title="${name.long}">${name.short}</abbr></li>`).join('')}</ul>
            <ol>
            ${[...Array(numOfDays).keys()].map(i => {
                const cur = new Date(year, month, i + 1);
                let day = cur.getDay(); if (day === 0) day = 7;
                const today = renderToday && (config.today.day === i + 1) ? ' data-today':'';
                return `<li data-day="${day}"${today}${i === 0 || day === config.info.firstDay ? ` data-weeknumber="${new Intl.NumberFormat(locale).format(getWeek(cur))}"`:''}${config.info.weekend.includes(day) ? ` data-weekend`:''}>
                    <time datetime="${year}-${(pad(month))}-${pad(i)}" tabindex="0" onclick="highlightDay(this)">${new Intl.NumberFormat(locale).format(i + 1)}</time>
                </li>`
            }).join('')}
            </ol>
        </kal-el>`;
    }

    const weekdays = (firstDay, locale) => {
        const date = new Date(0);
        const arr = [...Array(7).keys()].map(i => {
            date.setDate(5 + i)
            return {
                    long: new Intl.DateTimeFormat([locale], { weekday: 'long'}).format(date),
                    short: new Intl.DateTimeFormat([locale], { weekday: 'short'}).format(date)
                }
        })
        for (let i = 0; i < 8 - firstDay; i++) arr.splice(0, 0, arr.pop());
        return arr;
    }

    const today = new Date();
    const config = Object.assign({ locale: (document.documentElement.getAttribute('lang') || 'en-US'), today: { day: today.getDate(), month: today.getMonth(), year: today.getFullYear() } }, settings);
    const date = config.date ? new Date(config.date) : today;
    if (!config.info) config.info = new Intl.Locale(config.locale).weekInfo || { firstDay: 7, weekend: [6, 7] };
    return config.year ? [...Array(12).keys()].map(i => render(new Date(date.getFullYear(), i, date.getDate()), config.locale, date.getMonth())).join('') : render(date, config.locale)
}

function getStartOfMonth(year, month_num) {
    // Create a new Date object for the first day of the specified month
    var startDate = new Date(year, month_num - 1, 1); // Subtract 1 from month_num because months are one-indexed

    // Format the date as "YYYY-MM-DD"
    var formattedStartDate = startDate.getFullYear() + '-' + ('0' + (startDate.getMonth() + 1)).slice(-2) + '-' + ('0' + startDate.getDate()).slice(-2);

    return formattedStartDate;
}


function getendOfMonth(year, month_num) {
    // Create a new Date object for the first day of the specified month
    var endDate = new Date(year, month_num, 1); // Create a new Date object for the first day of the next month
    endDate.setDate(endDate.getDate() - 1); // Subtract one day to get the last day of the current month


    // Format the date as "YYYY-MM-DD"
    var formattedendDate = endDate.getFullYear() + '-' + ('0' + (endDate.getMonth() + 1)).slice(-2) + '-' + ('0' + endDate.getDate()).slice(-2);

    return formattedendDate;
}

const submitBtn = document.getElementById('submitBtn');


const submitFunction = () => {
    $.each(selectedDates, function(month, dates) {
        var year = new Date().getFullYear();
        var monthData = {}; // Object to store aggregated dates for the month

        var startDate = new Date(year, month, 1); // Start date of the month
        console.log("Check start date:", startDate);

        var endDate = new Date(year, month, 1); // End date of the month

        // Format start date and end date as ISO 8601 strings
        var formattedStartDate = startDate.toISOString().split('T')[0];
        console.log("Check start date2:", startDate);
        var formattedEndDate = endDate.toISOString().split('T')[0];

        // Add start date and end date to monthData
        monthData['start_date'] = formattedStartDate;
        monthData['end_date'] = formattedEndDate;

        $.each(dates, function(index, date) {
            var dayOfMonth = date.getDate(); // Get the day of the month

            // Determine the target key based on the day of the month
            var targetKey = 'd' + dayOfMonth;

            if (targetKey) { // Proceed only if a valid target key is determined
                monthData[targetKey] = date.toLocaleDateString(); // Store date in monthData
            } else {
                console.log("Invalid day of the month:", dayOfMonth);
            }
        });

        // Construct data object for the month with aggregated dates
        var data = {
            month: (parseInt(month)).toString(),
            year: year.toString(),
            status: "ACTIVE",
            ...monthData // Spread monthData to include all dates in the object
        };

        console.log("Inserting dates for month:", data);

        $.ajax({
            url: "/Admin/calendar/management/Admin/get/dates",
            method: "POST",
            data: { data: data, _csrf_token: $("#csrf").val() },
            success: function(response) {
                // Display success message with SweetAlert
                Swal.fire({
                    icon: 'success',
                    title: 'Success!',
                    text: 'Calendar Submitted for Approval: '
                });
                setTimeout(function() {
                    location.reload();
                }, 2000);
            },
            error: function(xhr, status, error) {
                // Display error message with SweetAlert
                Swal.fire({
                    icon: 'error',
                    title: 'Error!',
                    text: 'Error inserting dates for month: ' + error
                });
            }
        });
        
    });
    // Clear selectedDates after successful insertion
    selectedDates = {};
};

// Attach the event listener for the submit button
submitBtn.addEventListener('click', submitFunction);




function getWeek(cur) {
    const date = new Date(cur.getTime());
    date.setHours(0, 0, 0, 0);
    date.setDate(date.getDate() + 3 - (date.getDay() + 6) % 7);
    const week = new Date(date.getFullYear(), 0, 4);
    return 1 + Math.round(((date.getTime() - week.getTime()) / 86400000 - 3 + (week.getDay() + 6) % 7) / 7);
}

// Ensure that selectedDates is initialized as an object
let selectedDates = {};

// Modify the highlightDay function to use an object instead of an array
function highlightDay(element) {
    const datetime = element.getAttribute('datetime');
    const date = new Date(datetime);
    const month = date.getMonth() + 1;
    const year = date.getFullYear();

    element.classList.toggle("selected-date");

    if (!selectedDates.hasOwnProperty(month)) {
        selectedDates[month] = [];
    }

    const index = selectedDates[month].findIndex(selectedDate => selectedDate.getTime() === date.getTime());

    if (index === -1) {
        selectedDates[month].push(date);
    } else {
        selectedDates[month].splice(index, 1);
    }

    if (element.classList.contains("selected-date")) {
        element.style.backgroundColor = "green";
    } else {
        element.style.backgroundColor = "";
    }

    console.log("Selected Dates:", selectedDates);
}

// Modify the submitFunction to iterate over selectedDates keys

// Additionally, you might want to remove the previous check for attaching the event listener,
// as it's not necessary anymore since we're attaching it directly.

// Call kalEl function to initialize the calendar




document.addEventListener("DOMContentLoaded", function() {
    var app = document.getElementById("app");
    // var submit_button = document.getElementById("submitBtn");
    var lang = document.getElementById("lang");

    // Function to set innerHTML based on dataset
    function setInnerHTML() {
        app.innerHTML = kalEl(app.dataset);
        // submit_button.style.display = "none"; // Hide submit button
    }

    // Hide jor-el element initially
    app.style.display = "none";

    // Set innerHTML on page load
    setInnerHTML();

    // Add event listener to the select element
    lang.addEventListener('change', function() {
        document.documentElement.lang = lang.value;
        // Show jor-el element when a different option is selected
        // Set innerHTML when select option changes
        setInnerHTML();
    });
});