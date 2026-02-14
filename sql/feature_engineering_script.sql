DROP TABLE IF EXISTS ml_patent_base CASCADE;

-- feature table for modeling
CREATE TABLE ml_patent_base AS
WITH base AS (

    -- join patent + application info
    SELECT
        p.patent_id,
        p.patent_type,
        p.patent_date,
        p.wipo_kind,
        p.num_claims,
        p.withdrawn,
        p.filename,

        -- issue date parts
        EXTRACT(YEAR FROM p.patent_date)  AS patent_year,
        EXTRACT(MONTH FROM p.patent_date) AS patent_month,
        EXTRACT(DAY FROM p.patent_date)   AS patent_day,

        -- filing date
        a.filing_date::date AS filing_date_parsed,
        EXTRACT(YEAR FROM a.filing_date::date)  AS filing_year,
        EXTRACT(MONTH FROM a.filing_date::date) AS filing_month,
        EXTRACT(DAY FROM a.filing_date::date)   AS filing_day

    FROM g_patent p
    LEFT JOIN g_application a USING (patent_id)
),

agg AS (
    SELECT
        b.*,

        -- inventor + assignee counts
        (SELECT COUNT(*) FROM g_inventor_disambiguated i
         WHERE i.patent_id = b.patent_id) AS inventor_count,

        (SELECT COUNT(*) FROM g_assignee_disambiguated s
         WHERE s.patent_id = b.patent_id) AS assignee_count,

        -- citation counts
        (SELECT COUNT(*) FROM g_us_patent_citation c
         WHERE c.patent_id = b.patent_id) AS citations_made,

        (SELECT COUNT(*) FROM g_us_patent_citation c
         WHERE c.citation_patent_id = b.patent_id) AS citations_received,

        -- cpc + uspc counts
        (SELECT COUNT(*) FROM g_cpc_at_issue c
         WHERE c.patent_id = b.patent_id) AS cpc_count,

        (SELECT COUNT(*) FROM g_uspc_at_issue u
         WHERE u.patent_id = b.patent_id) AS uspc_count,

        -- flags
        CASE WHEN assignee_count > 0 THEN 1 ELSE 0 END AS has_assignee,
        CASE WHEN inventor_count > 1 THEN 1 ELSE 0 END AS multiple_inventors,
        CASE WHEN b.withdrawn THEN 1 ELSE 0 END AS withdrawn_flag,

        -- first CPC section
        (SELECT c.cpc_section
         FROM g_cpc_at_issue c
         WHERE c.patent_id = b.patent_id
         ORDER BY c.cpc_sequence
         LIMIT 1) AS primary_cpc_section,

        -- simple text lengths
        LENGTH(b.filename)     AS filename_length,
        0 AS title_length,

        -- numeric encoding for wipo kind
        CASE
            WHEN b.wipo_kind LIKE 'A%' THEN 1
            WHEN b.wipo_kind LIKE 'B%' THEN 2
            WHEN b.wipo_kind LIKE 'C%' THEN 3
            ELSE 0
        END AS wipo_kind_numeric,

        -- time from filing to issue
        (b.patent_date - b.filing_date_parsed) AS time_to_issue_days,

        -- number of distinct CPC sections
        (SELECT COUNT(DISTINCT c.cpc_section)
         FROM g_cpc_at_issue c
         WHERE c.patent_id = b.patent_id) AS cpc_section_breadth,

        -- early CPC assignment flag
        CASE WHEN (
            SELECT MIN(c.cpc_action_date::date)
            FROM g_cpc_at_issue c
            WHERE c.patent_id = b.patent_id
        ) <= b.filing_date_parsed + INTERVAL '365 days'
        THEN 1 ELSE 0 END AS early_cpc_flag,

        -- assignee is company vs individual
        CASE WHEN EXISTS (
            SELECT 1 FROM g_assignee_disambiguated s
            WHERE s.patent_id = b.patent_id AND s.assignee_type = 2
        ) THEN 1 ELSE 0 END AS assignee_is_company,

        CASE WHEN EXISTS (
            SELECT 1 FROM g_assignee_disambiguated s
            WHERE s.patent_id = b.patent_id AND s.assignee_type = 1
        ) THEN 1 ELSE 0 END AS assignee_is_individual,

        -- influence score
        (
            (SELECT COUNT(*) FROM g_us_patent_citation c
             WHERE c.citation_patent_id = b.patent_id)
            * LN(b.num_claims + 1)
        ) AS influence_score,

        -- summer grant flag
        CASE WHEN EXTRACT(MONTH FROM b.patent_date) BETWEEN 6 AND 8
        THEN 1 ELSE 0 END AS is_summer_grant

    FROM base b
)

SELECT * FROM agg;
