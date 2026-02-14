DROP TABLE IF EXISTS g_patent;

-- g_patent
CREATE TABLE g_patent (
    patent_id   TEXT PRIMARY KEY,
    patent_type TEXT,
    patent_date DATE,
    patent_title TEXT,
    wipo_kind   TEXT,
    num_claims  INTEGER,
    withdrawn   BOOLEAN,
    filename    TEXT
);



-- g_application
DROP TABLE IF EXISTS g_application;

CREATE TABLE g_application (
    application_id TEXT,
    patent_id TEXT,
    patent_application_type TEXT,
    filing_date TEXT,
    series_code TEXT,
    rule_47_flag INTEGER
);

-- g_assignee_disambiguated
DROP TABLE IF EXISTS g_assignee_disambiguated CASCADE;
CREATE TABLE g_assignee_disambiguated (
    patent_id TEXT,
    assignee_sequence INTEGER,
    assignee_id TEXT,
    disambig_assignee_individual_name_first TEXT,
    disambig_assignee_individual_name_last TEXT,
    disambig_assignee_organization TEXT,
    assignee_type INTEGER,
    location_id TEXT
);


-- g_inventor_disambiguated
DROP TABLE IF EXISTS g_inventor_disambiguated CASCADE;
CREATE TABLE g_inventor_disambiguated (
    patent_id TEXT,
    inventor_sequence INTEGER,
    inventor_id TEXT,
    disambig_inventor_name_first TEXT,
    disambig_inventor_name_last TEXT,
    gender_code TEXT,
    location_id TEXT
);


-- g_cpc_at_issue
DROP TABLE IF EXISTS g_cpc_at_issue CASCADE;
CREATE TABLE g_cpc_at_issue (
    patent_id TEXT,
    cpc_sequence INTEGER,
    cpc_version_indicator TEXT,
    cpc_section TEXT,
    cpc_class TEXT,
    cpc_subclass TEXT,
    cpc_group TEXT,
    cpc_type TEXT,
    cpc_action_date TEXT
);


-- g_us_patent_citation
DROP TABLE IF EXISTS g_us_patent_citation CASCADE;
CREATE TABLE g_us_patent_citation (
    patent_id TEXT,
    citation_sequence INTEGER,
    citation_patent_id TEXT,
    citation_date TEXT,
    record_name TEXT,
    wipo_kind TEXT,
    citation_category TEXT
);


-- g_uspc_at_issue
DROP TABLE IF EXISTS g_uspc_at_issue CASCADE;
CREATE TABLE g_uspc_at_issue (
    patent_id TEXT,
    uspc_sequence INTEGER,
    uspc_mainclass_id TEXT,
    uspc_mainclass_title TEXT,
    uspc_subclass_id TEXT,
    uspc_subclass_title TEXT
);