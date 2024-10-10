

function EnsureList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The identity of the list.")]
        [string]$ListIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "Template for the list.")]
        [ValidateSet("NoListTemplate", "GenericList", "DocumentLibrary", "Survey", "Links", "Announcements", "Contacts", "Events", "Tasks", "DiscussionBoard", "PictureLibrary", "DataSources", "WebTemplateCatalog", "UserInformation", "WebPartCatalog", "ListTemplateCatalog", "XMLForm", "MasterPageCatalog", "NoCodeWorkflows", "WorkflowProcess", "WebPageLibrary", "CustomGrid", "SolutionCatalog", "NoCodePublic", "ThemeCatalog", "DesignCatalog", "AppDataCatalog", "AppFilesCatalog", "DataConnectionLibrary", "WorkflowHistory", "GanttTasks", "HelpLibrary", "AccessRequest", "PromotedLinks", "TasksWithTimelineAndHierarchy", "MaintenanceLogs", "Meetings", "Agenda", "MeetingUser", "Decision", "MeetingObjective", "TextBox", "ThingsToBring", "HomePageLibrary", "Posts", "Comments", "Categories", "Facility", "Whereabouts", "CallTrack", "Circulation", "Timecard", "Holidays", "IMEDic", "ExternalList", "MySiteDocumentLibrary", "IssueTracking", "AdminTasks", "HealthRules", "HealthReports", "DeveloperSiteDraftApps", "ContentCenterModelLibrary", "ContentCenterPrimeLibrary", "ContentCenterSampleLibrary", "AccessApp", "AlchemyMobileForm", "AlchemyApprovalWorkflow", "SharingLinks", "HashtagStore", "RecipesTable", "FormulasTable", "WebTemplateExtensionsList", "ItemReferenceCollection", "ItemReferenceReference", "ItemReferenceReferenceCollection", "InvalidType")]
        [string]$Template,

        [Parameter(Mandatory = $true, HelpMessage = "Relative URL for the list.")]
        [ValidatePattern("^(?!http|/).*")]
        [string]$Url
    )

    $List = Get-PnPList -Identity $ListIdentity -ErrorAction SilentlyContinue
    
    if (-not $List) {
        # If the list does not exist, create a new one
        New-PnPList -Title $ListIdentity -Template $Template -Url $Url 
    }
    else {
        Write-Warning "List already exists!"
    }
}





























































