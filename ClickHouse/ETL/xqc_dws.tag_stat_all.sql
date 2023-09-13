SELECT
    day,
    company_id, shop_id,
    platform, seller_nick, snick,
    tag_dim.qc_norm_id,
    tag_dim.qc_norm_name,
    tag_dim.qc_norm_group_id,
    tag_dim.qc_norm_group_name,
    tag_dim.qc_norm_group_full_name,
    tag_type, tag_id, tag_dim.tag_name,
    tag_cnt_sum, tag_score_sum, tag_dialog_cnt, tag_manual_dialog_cnt
FROM (
    SELECT
        day,
        company_id, shop_id, platform, seller_nick, snick,
        tag_type, tag_id,
        tag_cnt_sum, tag_score_sum, tag_dialog_cnt, tag_manual_dialog_cnt
    FROM (
        SELECT
            day,
            platform, seller_nick, snick,
            tag_type, tag_id,
            SUM(tag_cnt) AS tag_cnt_sum,
            -- 同一个ID分数可能发生变化, 以实际打标为准
            SUM(tag_score*tag_cnt) AS tag_score_sum,
            uniqExact(dialog_id) AS tag_dialog_cnt,
            uniqExactIf(dialog_id, manual_checked>0) AS tag_manual_dialog_cnt
        FROM (
            -- 新版本AI质检项-非情绪扣分项
            SELECT
                toYYYYMMDD(begin_time) AS day,
                platform,
                seller_nick,
                snick,
                'ai_abnormal' AS tag_type,
                _id AS dialog_id,
                notEmpty(last_mark_id) AS manual_checked,
                abnormals_rule_id AS tag_ids,
                abnormals_count AS tag_cnts,
                abnormals_score AS tag_scores
            FROM dwd.xdqc_dialog_all
            WHERE toYYYYMMDD(begin_time) = {ds_nodash}
            -- 过滤新版本AI质检-扣分项
            AND arrayExists((x)->x!='',abnormals_rule_id)

            -- 新版本AI质检项-非情绪加分项
            UNION ALL
            SELECT
                toYYYYMMDD(begin_time) AS day,
                platform,
                seller_nick,
                snick,
                'ai_excellent' AS tag_type,
                _id AS dialog_id,
                notEmpty(last_mark_id) AS manual_checked,
                excellents_rule_id AS tag_ids,
                excellents_count AS tag_cnts,
                excellents_score AS tag_scores
            FROM dwd.xdqc_dialog_all
            WHERE toYYYYMMDD(begin_time) = {ds_nodash}
            -- 过滤新版本AI质检-加分项
            AND arrayExists((x)->x!='',excellents_rule_id)

            -- 新版本AI质检项-买家情绪项
            UNION ALL
            SELECT
                toYYYYMMDD(begin_time) AS day,
                platform,
                seller_nick,
                snick,
                'ai_c_emotion' AS tag_type,
                _id AS dialog_id,
                notEmpty(last_mark_id) AS manual_checked,
                c_emotion_rule_id AS tag_ids,
                c_emotion_count AS tag_cnts,
                c_emotion_score AS tag_scores
            FROM dwd.xdqc_dialog_all
            WHERE toYYYYMMDD(begin_time) = {ds_nodash}
            -- 过滤新版本AI质检-买家情绪项
            AND arrayExists((x)->x!='',c_emotion_rule_id)

            -- 新版本AI质检项-客服情绪项
            UNION ALL
            SELECT
                toYYYYMMDD(begin_time) AS day,
                platform,
                seller_nick,
                snick,
                'ai_s_emotion' AS tag_type,
                _id AS dialog_id,
                notEmpty(last_mark_id) AS manual_checked,
                s_emotion_rule_id AS tag_ids,
                s_emotion_count AS tag_cnts,
                s_emotion_score AS tag_scores
            FROM dwd.xdqc_dialog_all
            WHERE toYYYYMMDD(begin_time) = {ds_nodash}
            -- 过滤新版本AI质检-客服情绪项
            AND arrayExists((x)->x!='',s_emotion_rule_id)
        ) AS ods_ai_tag
        ARRAY JOIN
            tag_ids AS tag_id,
            tag_cnts AS tag_cnt,
            tag_scores AS tag_score
        -- 排除空数据
        WHERE tag_id!='' AND tag_cnt!=0
        GROUP BY
            day, platform, seller_nick, snick, tag_type, tag_id
    ) AS tag_stat
    GLOBAL LEFT JOIN (
        SELECT
            company_id, shop_id, platform, seller_nick, snick
        FROM xqc_dim.snick_full_info_all
        WHERE day = {snapshot_ds_nodash}
    ) AS snick_dim
    USING(platform, seller_nick, snick)
) AS ods_ai_tag
GLOBAL LEFT JOIN (
    SELECT
        company_id,
        platform,
        tag_info.tag_id,
        tag_info.tag_name,
        tag_info.qc_norm_id,
        tag_info.qc_norm_group_id,
        tag_group_info.qc_norm_name,
        tag_group_info.qc_norm_group_name,
        tag_group_info.qc_norm_group_full_name
    FROM (
        SELECT
            _id AS tag_id,
            name AS tag_name,
            qc_norm_id,
            qc_norm_group_id
        FROM xqc_dim.qc_rule_all
        WHERE day = {snapshot_ds_nodash}
    ) AS tag_info
    GLOBAL INNER JOIN (
        SELECT
            company_id,
            platform,
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
                company_id,
                platform,
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
) AS tag_dim
USING(company_id, tag_id)