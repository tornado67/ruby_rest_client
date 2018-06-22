#!/usr/bin/ruby
# encoding: utf-8

load '/home/arujitskii/tt_ops/sql.rb' #файл с SQL запросами
require '/home/arujitskii/tt_ops/sql.rb'
require 'rest-client'
require 'mysql'
require 'date'
require 'json'
require 'openssl'
require 'active_support/all'
require 'optparse'
require 'ostruct'
#Игнорируем недоверенный сертификат.
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
begin 
###############################################################################################################################################################
###########################################################               Variable secction               #####################################################
###############################################################################################################################################################
  $host2 = '10.xx.xx.xx'        
	$ping_db ='10.xx.xx.xx'
	$user='user'
	$pass='VERY_STRONG'
	$db = 'reports'
	#$_date     =  DateTime.now	- 1

###############################################################################################################################################################
##########################################################               Function Section                 #####################################################
###############################################################################################################################################################

	#функция получает данные от API сервера и возвращает их в формает JSON	
	def get_json_tt(index,date)
		url= "https://d01passportlb3p.main.russianpost.ru/postoffice/v1/object/#{index}/schedule?date=#{date}&daycount=1"
		#Формируем сроку запроса, конвертируем ее в URI, и шлём  подальше (всмысле к серверу :) ).
		return response  = Net::HTTP.get(URI.parse(url))
		
	end
	# Функция открывает подключение к БД
	def open_db_con(host)
		connection = Mysql.new host, $user, $pass  #получаем объект представляющий подключение согласно заданнмы параметрам
		rescue Mysql::Error => e
                    p e.errno
                    p e.error
		return  connection
		
	end


	def valid_json?(json)
   		 JSON.parse(json)
		    return true
		  rescue JSON::ParserError => e
		    return false
	end

	# Функция обрабатывает объект json и вставляет данные в БД
	def parse_json_tt(response,con)
	#Из ответа выбираем
		return if not valid_json?(response)			
                
	        $dmy      = DateTime.strptime(JSON.parse(response)['date'].to_s,'%Y%m%d').strftime('%Y-%m-%d')  # а так же строку вида год-месяц-день (Это нам потребуется для записи в базу )
		week      = ["понедельник","вторник","среда","четверг","пятница","суббота","воскресенье"] 
		$_begin   = JSON.parse(response)['dates'][0]['periods'][0]['begin'] #начало работы ОПС
		$_end     = JSON.parse(response)['dates'][0]['periods'][0]['end']   #и его конец
		$weekday  = week [ JSON.parse(response)['dates'][0]['weekday'] -1 ] # так же получаем  день недели (имеено через API чтобы быть уверенными в том, что все с ними ок)
		$mode     = JSON.parse(response)['dates'][0]['description'] #и получаем тип расписаниея: штатное, временное, праздничное
		$index    = JSON.parse(response)['object']
		$name     = JSON.parse(response)['name']

		#con.query(set_names_utf8)
		con.query(insert);

		rescue Mysql::Error => e
			puts e.errno
			puts e.error
		rescue ArgumentError => e	
			p response
			return
		rescue	NoMethodError =>e
			p response
			return
	end
	
#################################################################################################################################################################
#########################################################              Execution Section                 ########################################################
#################################################################################################################################################################

        options = OpenStruct.new
        OptionParser.new do |opt|
            opt.on('-d','--days DAYS', "set date current-date - n") { |o| options.days = o }
        end.parse!
 
        # если опция отсутствует то значение по-умолчанпю - 1
        unless  options.days.nil?
       
             $date   =  DateTime.now - options.days.to_i.day
        else 
             $date   =  DateTime.now - 1.day
        end
      

        $year   =  $date.strftime("%Y") #извлекаем год

        $month  =  $date.strftime("%m") # месяц

        $day    =  $date.strftime("%d") # день

        $dmy    =  $date.strftime("%Y-%m-%d") # а так же строку вида год-месяц-день

	con = open_db_con($ping_db)
	con.query(set_names_utf8)
        con2 = open_db_con($host2) # подключение к основному кластеру

	#выбираем индексы ОПС
        # самое ахуительно интересное начинается здесь. поскольку у заббикса раздвоение сука личности то:
        # подклюаемся к основному заббиксу
        # выбираем аптайм хостов подходящих к шаблону из PostIndex
        con.query(select_ops_indexes).each do |h|
            $host = h[0] # массив, хули.
            # по каждому хосту смотрим аптайм
            con2.query(get_host_uptime).each do |result|
              # ОПС идентифиуирцется по индексу, его и получаем
                $host_name = $host 
                             
                if  result[1].nil? 
                    $time_start  = "No data"   
                else
                    $time_start  = result[1].to_s[11..-4]  
                end

                if  result[2].nil?
                    $time_end  = "No data"
                else                                                                                                
                    $time_end  = result[2].to_s[11..-4]
                end   

                con.query(insert_host_uptime)
               
            end
        end        

        con.query(select_ops_indexes).each do |db|
                
        	json=get_json_tt(db.join("\s"),$date.strftime('%Y%m%d'))
            
                parse_json_tt(json,con)
        end

	rescue Mysql::Error => e
	    p e.errno
	    p e.error

	ensure
	    con.close if con
	    con2.close if con2
	    
end
