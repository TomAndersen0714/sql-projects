SELECT
    day,
    snick_dim.company_id,
    snick_dim.shop_id,
    platform, seller_nick, snick,
    snick_dim.employee_id,
    snick_dim.employee_name,
    snick_dim.department_id,
    snick_dim.department_name,
    snick_dim.qc_norm_id,
    snick_dim.qc_norm_name,
    snick_dim.qc_norm_tag_cnt,
    snick_dim.qc_norm_ai_tag_cnt,
    snick_dim.qc_norm_custom_tag_cnt,
    snick_dim.qc_norm_manual_tag_cnt,
    snick_dim.qc_norm_alert_tag_cnt,
    -- 分值统计-总计
    subtract_score_sum,
    add_score_sum,
    -- 分值统计-AI质检
    ai_subtract_score_sum,
    ai_add_score_sum,
    -- 分值统计-自定义质检
    custom_subtract_score_sum,
    custom_add_score_sum,
    -- 分值统计-人工质检
    manual_subtract_score_sum,
    manual_add_score_sum,
    -- 分值统计-会话平均分
    dialog_score_avg,

    -- 会话量统计-总计
    dialog_cnt,
    -- 会话量统计-优秀会话量
    excellent_dialog_cnt,
    -- 会话量统计-总计-打标会话量
    tagged_dialog_cnt,
    -- 会话量统计-总计-AI质检打标会话量
    ai_tagged_dialog_cnt,
    -- 会话量统计-总计-自定义质检打标会话量
    custom_tagged_dialog_cnt,
    -- 会话量统计-总计-人工质检打标会话量
    manual_tagged_dialog_cnt,

    -- 会话量统计-总计-扣分会话量
    subtract_score_dialog_cnt,
    -- 会话量统计-总计-加分会话量统计
    add_score_dialog_cnt,
    -- 会话量统计-总计-被人工质检会话量
    manual_marked_dialog_cnt,
    -- 会话量统计-AI质检
    ai_subtract_score_dialog_cnt,
    ai_add_score_dialog_cnt,
    ai_zero_score_tagged_dialog_cnt,
    -- 会话量统计-自定义质检
    custom_subtract_score_dialog_cnt,
    custom_add_score_dialog_cnt,
    custom_zero_score_tagged_dialog_cnt,
    -- 会话量统计-人工质检
    manual_subtract_score_dialog_cnt, -- 人工质检扣分打标会话量
    manual_add_score_dialog_cnt, -- 人工质检加分打标会话量
    manual_zero_score_tagged_dialog_cnt, -- 人工质检零分打标会话量
FROM (
    SELECT
        toYYYYMMDD(begin_time) AS day,
        platform,
        seller_nick,
        snick,
        -- 质检项数量统计-总计
        dialog_ai_tag_cnt + dialog_custom_tag_cnt + dialog_manual_tag_cnt AS dialog_tag_cnt,
        -- 质检项数量统计-AI
        arraySum(abnormals_count) + arraySum(excellents_count)
            + arraySum(s_emotion_count) + arraySum(c_emotion_count) AS dialog_ai_tag_cnt,
        -- 质检项数量统计-自定义
        arraySum(xrule_stats_count) + arraySum(top_xrules_count) AS dialog_custom_tag_cnt,
        -- 质检项数量统计-人工
        arraySum(tag_score_stats_count) + arraySum(tag_score_stats_md) +
            arraySum(tag_score_add_stats_count)  + arraySum(tag_score_add_stats_md)  AS dialog_manual_tag_cnt,

        -- 分值统计-总计
        sum(score) AS subtract_score_sum,
        sum(score_add) AS add_score_sum,
        -- 分值统计-人工质检
        sum(mark_score) AS manual_subtract_score_sum,
        sum(mark_score_add) AS manual_add_score_sum,
        -- 分值统计-自定义质检
        sum(
            arraySum(rule_stats_score)
            +
            negate(arraySum(arrayMap((x,y) -> x*if(y<0,y,0), xrule_stats_count, xrule_stats_score)))
            +
            negate(arraySum(arrayMap((x,y) -> x*if(y<0,y,0), top_xrules_count, top_xrules_score)))
        ) AS custom_subtract_score_sum,
        sum(
            arraySum(rule_add_stats_score)
            +
            arraySum(arrayMap((x,y) -> x*if(y>0,y,0), xrule_stats_count, xrule_stats_score))
            +
            arraySum(arrayMap((x,y) -> x*if(y>0,y,0), top_xrules_count, top_xrules_score))
        ) AS custom_add_score_sum,
        -- 分值统计-AI质检
        subtract_score_sum - manual_subtract_score_sum - custom_subtract_score_sum AS ai_subtract_score_sum,
        add_score_sum - manual_add_score_sum - custom_add_score_sum AS ai_add_score_sum,
        -- 分值统计-会话平均分
        IF(dialog_cnt>0, (100*dialog_cnt+add_score_sum-subtract_score_sum)/dialog_cnt, 0) AS dialog_score_avg,

        -- 会话量统计-总计
        uniqExact(_id) AS dialog_cnt,
        SUM(100 + add_score - score >= 90) AS excellent_dialog_cnt,

        -- 会话量统计-总计-打标会话量
        uniqExactIf(
            _id,
            (
                length(arrayFilter(x->x!='', abnormals_rule_id)) + length(arrayFilter(x->x!='', excellents_rule_id)) +
                length(rule_stats_id) + length(xrule_stats_id) + length(top_xrules_id) +
                length(tag_score_add_stats_id) + length(tag_score_stats_id)
            )!=0
        ) AS tagged_dialog_cnt,
        -- 会话量统计-总计-AI质检打标会话量
        uniqExactIf(
            _id, (length(arrayFilter(x->x!='', abnormals_rule_id)) + length(arrayFilter(x->x!='', excellents_rule_id)))!=0
        ) AS ai_tagged_dialog_cnt,
        -- 会话量统计-总计-自定义质检打标会话量
        uniqExactIf(
            _id, (length(rule_stats_id) + length(xrule_stats_id) + length(top_xrules_id))!=0
        ) AS custom_tagged_dialog_cnt,
        -- 会话量统计-总计-人工质检打标会话量
        uniqExactIf(
            _id, (length(tag_score_add_stats_id) + length(tag_score_stats_id))!=0
        ) AS manual_tagged_dialog_cnt,
        -- 会话量统计-扣分会话量
        uniqExactIf(_id, score>0) AS subtract_score_dialog_cnt,
        -- 会话量统计-加分会话量
        uniqExactIf(_id, score_add>0) AS add_score_dialog_cnt,

        -- 会话量统计-AI质检
        sum((
            score - mark_score - (
                arraySum(rule_stats_score)
                +
                negate(arraySum(arrayMap((x,y) -> x*if(y<0,y,0), xrule_stats_count, xrule_stats_score)))
                +
                negate(arraySum(arrayMap((x,y) -> x*if(y<0,y,0), top_xrules_count, top_xrules_score)))
            )) > 0
        ) AS ai_subtract_score_dialog_cnt,
        sum((
            score_add - mark_score_add - (
                arraySum(rule_add_stats_score)
                +
                arraySum(arrayMap((x,y) -> x*if(y>0,y,0), xrule_stats_count, xrule_stats_score))
                +
                arraySum(arrayMap((x,y) -> x*if(y>0,y,0), top_xrules_count, top_xrules_score))
            )) > 0
        ) AS ai_add_score_dialog_cnt,
        sum((
            length(arrayFilter((x,y)->(x=0 AND y!=''), abnormals_score, abnormals_rule_id))
                + length(arrayFilter((x,y)->(x=0 AND y!=''), excellents_score, excellents_rule_id))
                + length(arrayFilter((x,y)->(x=0 AND y!=''), s_emotion_score, s_emotion_rule_id))
                + length(arrayFilter((x,y)->(x=0 AND y!=''), c_emotion_score, c_emotion_rule_id))
            )>0
        ) AS ai_zero_score_tagged_dialog_cnt,

        -- 会话量统计-自定义质检
        sum((
                length(arrayFilter(x->x<0, xrule_stats_score))
                +
                length(arrayFilter(x->x<0, top_xrules_score))
            )!=0
        ) AS custom_subtract_score_dialog_cnt,
        sum((
                length(arrayFilter(x->x>0, xrule_stats_score))
                +
                length(arrayFilter(x->x>0, top_xrules_score))
            )!=0
        ) AS custom_add_score_dialog_cnt,
        sum((
                length(arrayFilter((x,y)->(x=0 AND y!=''), xrule_stats_score, xrule_stats_id))
                +
                length(arrayFilter((x,y)->(x=0 AND y!=''), top_xrules_score, top_xrules_id))
            )>0
        ) AS custom_zero_score_tagged_dialog_cnt,

        -- 会话量统计-人工质检
        sum(length(mark_ids)!=0) AS manual_marked_dialog_cnt, -- 被人工质检会话量
        sum(arrayExists((x)->x>0, tag_score_stats_score)) AS manual_subtract_score_dialog_cnt, -- 人工质检扣分会话量
        sum(arrayExists((x)->x>0, tag_score_add_stats_score)) AS manual_add_score_dialog_cnt, -- 人工质检加分会话量
        sum((
                length(arrayFilter((x,y)->(x=0 AND y!=''), tag_score_stats_score, tag_score_stats_id))
                +
                length(arrayFilter((x,y)->(x=0 AND y!=''), tag_score_add_stats_score, tag_score_add_stats_id))
            )>0
        ) AS manual_zero_score_tagged_dialog_cnt
    FROM dwd.xdqc_dialog_all
    WHERE toYYYYMMDD(begin_time) = 20230812
    GROUP BY day, platform, seller_nick, snick
) AS dws_snick_stat
GLOBAL LEFT JOIN (
    -- 获取维度数据快照
    SELECT
        company_id, shop_id, platform, snick,
        employee_id, employee_name, department_id, department_name,
        qc_norm_id, qc_norm_name,
        qc_norm_tag_cnt, qc_norm_ai_tag_cnt, qc_norm_custom_tag_cnt, qc_norm_manual_tag_cnt, qc_norm_alert_tag_cnt
    FROM (
        SELECT
            company_id, shop_id, platform, snick,
            employee_id, employee_name, department_id, department_name
        FROM xqc_dim.snick_full_info_all
        WHERE day = 20230813
    ) AS snick_info
    GLOBAL LEFT JOIN (
        SELECT
            company_id, qc_norm_id, qc_norm_name, department_id,
            qc_norm_tag_cnt, qc_norm_ai_tag_cnt, qc_norm_custom_tag_cnt, qc_norm_manual_tag_cnt, qc_norm_alert_tag_cnt
        FROM (
            SELECT
                company_id, qc_norm_id, qc_norm_name,
                qc_norm_tag_cnt, qc_norm_ai_tag_cnt, qc_norm_custom_tag_cnt, qc_norm_manual_tag_cnt, qc_norm_alert_tag_cnt
            FROM (
                SELECT DISTINCT
                    company_id, _id AS qc_norm_id, name AS qc_norm_name
                FROM ods.xinghuan_qc_norm_all
                WHERE day = 20230813
            ) qc_norm_info
            GLOBAL LEFT JOIN (
                SELECT
                    qc_norm_id,
                    COUNT(1) AS qc_norm_tag_cnt,
                    SUM(rule_category = 1) AS qc_norm_ai_tag_cnt,
                    SUM(rule_category = 3) AS qc_norm_custom_tag_cnt,
                    SUM(rule_category = 2) AS qc_norm_manual_tag_cnt,
                    SUM(alert_level != 0) AS qc_norm_alert_tag_cnt
                FROM xqc_dim.qc_rule_all
                WHERE day = 20230813
                AND status = 1
                AND qc_norm_id != ''
                GROUP BY qc_norm_id
            ) AS qc_norm_cnt
            USING(qc_norm_id)
        ) AS qc_norm_info
        GLOBAL INNER JOIN (
            SELECT DISTINCT
                company_id, qc_norm_id, department_id
            FROM ods.xinghuan_qc_norm_relate_all
            WHERE day = 20230813
            AND company_id != '' AND qc_norm_id != ''
        ) AS qc_norm_department_map_info
        USING(company_id, qc_norm_id)
        WHERE company_id != '' AND department_id != ''
    ) AS qc_norm_department_info
    USING(company_id, department_id)
) AS snick_dim
USING(platform, snick)