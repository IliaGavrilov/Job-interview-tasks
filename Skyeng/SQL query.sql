SELECT USER_ID, MIN(MIN_SESSION) AS SESSION_BEGIN, MAX(MAX_SESSION) AS SESSION_END
  FROM (
    SELECT USER_ID, GRP, ACTIVITY_GRP, MIN(HAPPENED_AT) AS MIN_SESSION, MAX(HAPPENED_AT) AS MAX_SESSION,
           COUNT(DISTINCT ACTIVITY) AS ACT_COUNT
      FROM (
        SELECT *,
            SUM(GRP_BEGIN) OVER(PARTITION BY USER_ID ORDER BY HAPPENED_AT ROWS BETWEEN 1 FOLLOWING AND 1 FOLLOWING) AS GRP,
            SUM(ACT_BEGIN) OVER(PARTITION by USER_ID ORDER BY HAPPENED_AT ROWS BETWEEN 1 FOLLOWING AND 1 FOLLOWING) AS ACTIVITY_GRP
            FROM (
                SELECT *,
                    CASE WHEN COALESCE(EXTRACT('epoch' FROM HAPPENED_AT - LAG(HAPPENED_AT) OVER(partition BY USER_ID ORDER BY HAPPENED_AT)),0) < 3600 THEN 0 ELSE 1 END GRP_BEGIN,
                    CASE WHEN LAG(ACTIVITY) OVER(PARTITION BY USER_ID ORDER BY HAPPENED_AT) > ACTIVITY THEN 1 ELSE 0 END ACT_BEGIN
                    FROM (
                        SELECT *,
                            (CASE PAGE WHEN 'rooms.homework-showcase' THEN 1 WHEN 'rooms.view.step.content' THEN 2 WHEN 'rooms.lesson.rev.step.content' THEN 3 ELSE 4 END) ACTIVITY, EXTRACT('EPOCH' FROM HAPPENED_AT) - EXTRACT('epoch' FROM LAG(HAPPENED_AT) OVER(PARTITION BY USER_ID ORDER BY HAPPENED_AT)) AS LAG_TIMES
                            FROM test.vimbox_pages WHERE PAGE IN ('rooms.homework-showcase', 'rooms.view.step.content', 'rooms.lesson.rev.step.content') ORDER BY HAPPENED_AT)
            )
        )
    GROUP BY USER_ID, GRP, ACTIVITY_GRP
  ) 
  GROUP BY USER_ID, GRP
  HAVING MAX(ACT_COUNT) = 3
