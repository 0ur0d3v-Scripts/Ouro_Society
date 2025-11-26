$(function() {
    var currentJob = null;
    
    // Hide everything on load
    $(".container").hide();
    $("#showJobs").hide();
    $("#jobSelection").hide();
    $("#home").show();
    
    // Listen for messages from client
    window.addEventListener('message', function(event) {
        var data = event.data;
        
        if (data.action === "openJobCenter") {
            openJobCenter(data.jobs);
        } else if (data.action === "close") {
            closeUI();
        } else if (data.action === "updateLedger") {
            // Handle ledger updates if needed
        }
    });
    
    // Open job center UI
    function openJobCenter(allowedJobs) {
        $(".container").fadeIn(300);
        $("#home").show();
        $("#showJobs").hide();
        $("#jobSelection").hide();
        
        // Load jobs
        loadJobs(allowedJobs);
    }
    
    // Load jobs from configNui.js
    function loadJobs(allowedJobs) {
        if (typeof configs === 'undefined' || !configs.jobs) {
            console.error("Jobs config not found!");
            return;
        }
        
        // Clear existing jobs
        $(".whitelisted-jobs").empty();
        $(".unwhitelisted-jobs").empty();
        
        // Filter and display jobs
        configs.jobs.forEach(function(job) {
            // Only show jobs that are in allowedJobs array
            if (allowedJobs && !allowedJobs.includes(job.group)) {
                return;
            }
            
            var jobCard = $('<div class="job-card"></div>');
            
            if (job.whitelisted) {
                jobCard.addClass('whitelisted');
            }
            
            // Add icon
            if (job.iconName) {
                jobCard.append('<img src="assets/images/' + job.iconName + '" alt="' + job.title + '">');
            }
            
            // Add title and short description
            jobCard.append('<h3>' + job.title + '</h3>');
            jobCard.append('<p>' + job.shortDescription + '</p>');
            
            // Add click handler
            jobCard.click(function() {
                showJobDetails(job);
            });
            
            // Append to appropriate list
            if (job.whitelisted) {
                $(".whitelisted-jobs").append(jobCard);
            } else {
                $(".unwhitelisted-jobs").append(jobCard);
            }
        });
    }
    
    // Show job details
    function showJobDetails(job) {
        currentJob = job;
        
        $("#showJobs").hide();
        $("#jobSelection").fadeIn(300);
        
        // Set job icon
        if (job.iconName) {
            $(".jobIcon").attr('src', 'assets/images/' + job.iconName);
        }
        
        // Set job title
        $(".jobTitle").text(job.title);
        
        // Set job description
        $(".jobDescription").text(job.description);
        
        // Set requirements
        var requirementsText = "";
        if (job.requirements && job.requirements.length > 0) {
            job.requirements.forEach(function(req) {
                requirementsText += "- " + req + "\n";
            });
        } else {
            requirementsText = "No special requirements";
        }
        $(".jobRequirements").text(requirementsText);
        
        // Set select button text
        if (job.whitelisted) {
            $(".selectJob").text("View Application");
            $(".selectJob").off('click').click(function() {
                // For whitelisted jobs, just show info
                alert("This is a whitelisted job. Apply on our discord or website.");
            });
        } else {
            $(".selectJob").text("Accept Job");
            $(".selectJob").off('click').click(function() {
                selectJob(job);
            });
        }
    }
    
    // Select job
    function selectJob(job) {
        $.post('https://Ouro_Society/selectJob', JSON.stringify({
            job: job.group
        }));
        
        closeUI();
    }
    
    // Close UI
    function closeUI() {
        $(".container").fadeOut(300, function() {
            $("#home").show();
            $("#showJobs").hide();
            $("#jobSelection").hide();
            currentJob = null;
        });
        
        $.post('https://Ouro_Society/close', JSON.stringify({}));
    }
    
    // Close button
    $(".btnClose").click(function() {
        closeUI();
    });
    
    // ESC key to close
    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            closeUI();
        }
    });
    
    // Scroll to bottom
    window.scrollToBottom = function() {
        $("#scrollbox").animate({
            scrollTop: $("#scrollbox")[0].scrollHeight
        }, 1000);
    };
    
    // Open show jobs page
    window.openShowJobs = function() {
        $("#home").hide();
        $("#jobSelection").hide();
        $("#showJobs").fadeIn(300);
    };
});

