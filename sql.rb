def set_names_utf8 
<<-END_SQL.gsub(/\s+/, " ").strip
        SET NAMES utf8
END_SQL
end 

def insert
<<-END_SQL.gsub(/\s+/, " ").strip
	INSERT INTO `reports`.`r_time_table` (`_date`,`_name`,`_mode`,`_day`,`_index`,`_begin`,`_end`) 
	VALUES ( '#{$dmy}', '#{$name}', '#{$mode}', '#{$weekday}', #{$index} ,'#{$_begin}' , '#{$_end}' );
END_SQL
end


def select_ops_indexes 
<<-END_SQL.gsub(/\s+/, " ").strip
	SELECT OPSIndex FROM `reports`.`PostIndex`;
END_SQL
end

def get_host_uptime
<<-END_SQL.gsub(/\s+/, " ").strip
        SELECT  hosts.name, FROM_UNIXTIME( MIN( history_uint.`clock`) ) AS d1 ,FROM_UNIXTIME( MAX( history_uint.`clock`) ) AS d2
        FROM zabbix.`history_uint`,zabbix.`items` ,zabbix.`hosts`
        WHERE
        YEAR(FROM_UNIXTIME(history_uint.`clock`)) = #{$year} 
         AND MONTH(FROM_UNIXTIME(history_uint.`clock`)) =  #{$month}
         AND DAY(FROM_UNIXTIME(history_uint.`clock`))= #{$day} AND
        history_uint.`itemid` =items.`itemid` AND items.`key_` = 'agent.ping' AND items.`hostid` =hosts.`hostid` AND
        hosts.`name` LIKE '%#{$host}-N%'

END_SQL
end

def insert_host_uptime
<<-END_SQL
    INSERT INTO reports.r_ops_uptime VALUES (default,'#{$dmy}', '#{$host_name}', '#{$time_start}', '#{$time_end}' );
END_SQL
end
