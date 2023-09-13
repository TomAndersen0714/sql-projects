SELECT
    day,
    company_id, shop_id,
    seller_nick, platform, snick,
    employee_id, employee_name, department_id, department_name,
    mark_account_id, account_info.account_name AS mark_account_name,
    qc_norm_id, qc_norm_name, qc_norm_group_id, qc_norm_group_name, qc_norm_group_full_name,
    dialog_id, cnick, tag_id, tag_name, tag_score, cal_op
FROM (
    SELECT
        company_id, shop_id,
        seller_nick, platform, group, snick, employee_id, employee_name, department_id, department_name,
        mark_account_id,
        qc_norm_id, qc_norm_name, qc_norm_group_id, qc_norm_group_name, qc_norm_group_full_name,
        dialog_id, cnick, tag_id, tag_name, tag_score, cal_op, day
    FROM (
        SELECT
            tag_detial.seller_nick,
            tag_detial.platform,
            tag_detial.`group`,
            tag_detial.snick,
            tag_detial._id AS dialog_id,
            tag_detial.cnick,
            tag_detial.tag_id,
            tag_info.tag_name,
            tag_info.qc_norm_id,
            tag_info.qc_norm_group_id,
            tag_info.qc_norm_name,
            tag_info.qc_norm_group_name,
            tag_info.qc_norm_group_full_name,
            tag_detial.tag_score,
            0 AS cal_op,
            mark_account_id,
            day
        FROM (
            SELECT
                toYYYYMMDD(begin_time) AS day,
                platform,
                seller_nick,
                `group`,
                snick,
                _id,
                cnick,
                tag_id,
                tag_score,
                last_mark_id AS mark_account_id
            FROM dwd.xdqc_dialog_all
            ARRAY JOIN
                tag_score_stats_id AS tag_id,
                tag_score_stats_score AS tag_score
            WHERE toYYYYMMDD(begin_time) = {ds_nodash}
            AND length(tag_score_stats_id) > 0
        ) AS tag_detial
        LEFT JOIN (
            SELECT
                tag_info.tag_id,
                tag_info.tag_name,
                tag_info.qc_norm_id,
                tag_info.qc_norm_group_id,
                tag_group_info.qc_norm_name,
                tag_group_info.qc_norm_group_name,
                tag_group_info.qc_norm_group_full_name
            FROM (
                -- 筛选人工质检项
                SELECT
                    _id AS tag_id,
                    name AS tag_name,
                    qc_norm_id,
                    qc_norm_group_id
                FROM xqc_dim.qc_rule_all
                WHERE day = {snapshot_ds_nodash}
                AND rule_category = 2
            ) AS tag_info
            GLOBAL INNER JOIN (
                SELECT
                    qc_norm_id,
                    qc_norm_name,
                    qc_norm_group_id,
                    qc_norm_group_name,
                    qc_norm_group_full_name
                FROM (
                    SELECT
                        qc_norm_id,
                        _id AS qc_norm_group_id,
                        name AS qc_norm_group_name,
                        full_name AS qc_norm_group_full_name
                    FROM xqc_dim.qc_norm_group_full_all
                    WHERE day = {snapshot_ds_nodash}
                ) AS qc_norm_group_info
                GLOBAL INNER JOIN (
                    SELECT
                        _id AS qc_norm_id,
                        name AS qc_norm_name
                    FROM ods.xinghuan_qc_norm_all
                    WHERE day = {snapshot_ds_nodash}
                    AND qc_norm_id != ''
                ) AS qc_norm_info
                USING(qc_norm_id)
                WHERE qc_norm_id != '' AND qc_norm_group_id != ''
            ) AS tag_group_info
            USING(qc_norm_id, qc_norm_group_id)
        ) AS tag_info
        USING(tag_id)
    ) AS tag_detial
    GLOBAL LEFT JOIN (
        SELECT
            company_id, shop_id, platform, snick,
            employee_id, employee_name, department_id, department_name
        FROM xqc_dim.snick_full_info_all
        WHERE day = {snapshot_ds_nodash}
    ) AS snick_info
    USING(platform, snick)
) AS tag_detial
GLOBAL LEFT JOIN (
    SELECT
        _id AS account_id,
        username AS account_name
    FROM ods.xinghuan_account_all
    WHERE day = {snapshot_ds_nodash}
) AS account_info
ON tag_detial.mark_account_id = account_info.account_id