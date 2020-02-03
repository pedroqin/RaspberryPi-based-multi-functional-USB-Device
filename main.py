#!/usr/bin/env python
#-*- coding:utf8 -*-
###############################################
# Filename    :   main.py
# Author      :   PedroQin
# Email       :   pedro.hq.qin@mail.foxconn.com
# Date        :   2020-01-23 11:50:55
# Version     :   1.0.1
# Description :   
###############################################
 
import spidev as SPI
import ST7789
import time,os,sys,logging
import RPi.GPIO as GPIO
from PIL import Image,ImageDraw,ImageFont

# Raspberry Pi pin configuration:
RST = 27
DC = 25
BL = 24
BUS = 0 
DEVICE = 0 

KEY_UP_PIN     = 6 
KEY_DOWN_PIN   = 19
KEY_LEFT_PIN   = 5
KEY_RIGHT_PIN  = 26
KEY_PRESS_PIN  = 13

KEY1_PIN       = 21
KEY2_PIN       = 20
KEY3_PIN       = 16

# 240x240 display with hardware SPI:
disp = ST7789.ST7789(SPI.SpiDev(BUS, DEVICE),RST, DC, BL)
disp.Init() # Initialize library.
disp.clear() # Clear display.

#init GPIO
GPIO.setmode(GPIO.BCM) 
GPIO.setup(KEY_UP_PIN,      GPIO.IN, pull_up_down=GPIO.PUD_UP) # Input with pull-up
GPIO.setup(KEY_DOWN_PIN,    GPIO.IN, pull_up_down=GPIO.PUD_UP) # Input with pull-up
GPIO.setup(KEY_LEFT_PIN,    GPIO.IN, pull_up_down=GPIO.PUD_UP) # Input with pull-up
GPIO.setup(KEY_RIGHT_PIN,   GPIO.IN, pull_up_down=GPIO.PUD_UP) # Input with pull-up
GPIO.setup(KEY_PRESS_PIN,   GPIO.IN, pull_up_down=GPIO.PUD_UP) # Input with pull-up
GPIO.setup(KEY1_PIN,        GPIO.IN, pull_up_down=GPIO.PUD_UP) # Input with pull-up
GPIO.setup(KEY2_PIN,        GPIO.IN, pull_up_down=GPIO.PUD_UP) # Input with pull-up
GPIO.setup(KEY3_PIN,        GPIO.IN, pull_up_down=GPIO.PUD_UP) # Input with pull-up

whereami = os.path.dirname(os.path.abspath(__file__))

# Create blank image for drawing.
#image1 = Image.new("RGB", (disp.width, disp.height), "WHITE")
image1 = Image.open(os.path.join(whereami,"pic/bg.jpg"))
draw = ImageDraw.Draw(image1)
draw.line([(5,5),(235,5)], fill = "BLACK",width = 5)
draw.line([(235,5),(235,235)], fill = "BLACK",width = 5)
draw.line([(235,235),(5,235)], fill = "BLACK",width = 5)
draw.line([(5,235),(5,5)], fill = "BLACK",width = 5)


#my_font1 = ImageFont.truetype(os.path.join(whereami,"UniTortred.ttf"), 16)
my_font0 = ImageFont.truetype(os.path.join(whereami,"font/Soopafresh.ttf"), 80)
my_font1 = ImageFont.truetype(os.path.join(whereami,"font/Soopafresh.ttf"), 20)
my_font2 = ImageFont.truetype(os.path.join(whereami,"font/Soopafresh.ttf"), 16)
#my_font3 = ImageFont.truetype(os.path.join(whereami,"font/Bodoni_Bold_Italic.ttf"), 12)
#my_font3 = ImageFont.truetype(os.path.join(whereami,"font/Soopafresh.ttf"), 12)
my_font3 = ImageFont.truetype(os.path.join(whereami,"font/Geometr.ttf"), 12)

# history
all_centent=[]
max_lines_can_be_shown=17

# title -> command
menu_str="""
1. Get Status ->  ./get_info.sh Get_Status
2. U Disk Mode -> ./get_info.sh U-DiskMode
3. Ether Mode -> ./get_info.sh EtherMode
4. AP Mode -> ./get_info.sh EnableAP
5. Keyboard Mode -> ./get_info.sh PI-as-keyboard
6. Flash U Disk -> ./get_info.sh Flash_U_Disk
7. Re-GetIP -> ./get_info.sh Re-GetIP
8. Cat Cmdline -> ./get_info.sh CatCmdline
9. Cat WlanCfg -> ./get_info.sh CatWlanCfg
10. Export Log -> ./get_info.sh Export_log %s
11. REBOOT -> sync;reboot
12. POWEROFF -> sync;poweroff
13. EXIT -> exit
"""

# menu list
menu=[]
cmd=[]
select_index=0
cur_display_first=1
for str_tmp in menu_str.split("\n"):
    if not str_tmp : continue
    menu.append(str_tmp.split("->")[0].rstrip())
    cmd.append(str_tmp.split("->")[1])

# logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
log_name = os.path.join("/tmp","main_" + time.strftime("%Y%m%d%H%M%S", time.localtime()) + ".log")
file_handler = logging.FileHandler(filename = log_name,mode="w")
file_handler.setLevel(logging.DEBUG)
console_hander = logging.StreamHandler()
console_hander.setLevel(logging.DEBUG)

formatter = logging.Formatter("%(asctime)s %(name)s %(levelname)s %(message)s")
file_handler.setFormatter(formatter)
console_hander.setFormatter(formatter)
logger.addHandler(file_handler)
logger.addHandler(console_hander)

#key without jitter
interval_second=0.05

def format_str(input_str,skip_null=0,line_number=0):
    line_max_width=220
    result_str=[]
    index=0
    for str_tmp in input_str.split("\n"):
        if skip_null : 
            if not str_tmp : continue
        index += 1
        if line_number: str_tmp = str(index) + " " + str_tmp
        cur_width,cur_height=my_font3.getsize(str_tmp)
        if cur_width <= line_max_width:
            result_str.append(str_tmp)
        else:
            new_line=''
            for char in str_tmp:
                new_line += char
                cur_width,cur_height=my_font3.getsize(new_line)
                if cur_width > line_max_width:
                    result_str.append(new_line)
                    new_line='  '
                else: continue
            result_str.append(new_line)
    return result_str

# the header had use 50
def draw_header(color="YELLOW"):    
    # say hello
    image = Image.open(os.path.join(whereami,"pic/hi.jpg"))
    disp.ShowImage(image,0,0)

    # Draw a white filled box to clear the image
    draw.text((10, 10), 'IP :', fill = color, font=my_font1)
    draw.text((10, 30), os.popen("ip1=$(ifconfig wlan0 | awk '/inet / {print $2}');ip2=$(ifconfig usb0 2>/dev/null| awk '/inet / {print $2}');echo ${ip1:-$ip2}").read(), fill = color, font=my_font2)
    draw.text((120, 10), 'MODE :', fill = color, font=my_font1)
    draw.text((120, 30), os.popen("cat /proc/cmdline |grep -oE 'modules-load=[0-9a-z,_]+'|cut -d= -f2").read(), fill = color, font=my_font2)
    draw.line([(5,50),(235,50)], fill = "BLACK",width = 5)

# load average and temperature, three colors for three ranges
def draw_bottom():
    load_info = os.popen("cat /proc/loadavg|cut -d ' ' -f'-3'").read()
    min_load = float(load_info.split()[0])
    if min_load >= 1:
        color="RED"
    elif min_load >= 0.75 and min_load < 1.0:
        color="GOLD"
    else:
        color="BLUE"
    draw.text((10, 225), "Load: " + load_info, fill = color)
    temp_info = os.popen('echo "scale=3;$(cat /sys/class/thermal/thermal_zone0/temp)/1000" | bc').read()
    temp2float = float(temp_info)
    if temp2float >= 50:
        color="RED"
    elif temp2float >= 45 and temp2float < 50:
        color="GOLD"
    else:
        color="BLUE"
    draw.text((150, 225),"Temp: " + temp_info, fill = color)
    

# begin >= 0:begin at $begin line of centent ,-1 begin at end 
def draw_str(centent,begin=0,selected=0,color="BLUE"):
    x_offset = 10
    y_offset = 50
    single_line_height = 10
    max_width=220
    index_cur=0
    if begin >= 0 :
        centent=centent[begin:begin+max_lines_can_be_shown]
    elif begin < 0 : 
        centent=centent[-max_lines_can_be_shown:]
    for line in centent:
        if index_cur == selected:
            draw.rectangle((x_offset,y_offset+(index_cur)*single_line_height,x_offset+max_width,y_offset+(index_cur+1)*single_line_height),fill = "RED", outline=0)
        draw.text((x_offset, y_offset+(index_cur)*single_line_height), line, fill = color, font=my_font3)
        index_cur += 1

# begin at 50 , end at 235, minus the lines used by bottom :10 ,so draw_info begin at (5,50) and end at (225,225), width :220 , height 175
# max lines : 17 
def draw_info(info_str,color="BLUE"):
    global all_centent,cur_display_first,select_index
    draw.rectangle((5,50,235,235), fill = "WHITE", outline=0)
    draw_bottom()
    all_centent.extend(info_str)
    
    if select_index + 1 - max_lines_can_be_shown > cur_display_first :
        cur_display_first = select_index + 1 - max_lines_can_be_shown
    elif select_index - cur_display_first <= 0 :
        cur_display_first = select_index 
    draw_str(all_centent , begin = cur_display_first , selected=select_index - cur_display_first)
    disp.ShowImage(image1,0,0)

# show list / show cmd is different
def show(source_list,run_cmd=0):
    global select_index,cur_display_first,all_centent
    # clear all_centent
    all_centent=[]

    options_num=len(source_list)
    select_index = select_index % options_num
    if not run_cmd:
        draw_info(source_list)
    else:
        logger.debug("select: " + str(select_index) + " tittle: " + menu[select_index] + " cmd: " + cmd[select_index])
        command_str=cmd[select_index]
        if command_str.find("Export_log") > 0:
            command_str=command_str % log_name
        if command_str.strip() == "exit" :
            image = Image.open(os.path.join(whereami,"pic/bye.jpg"))
            disp.ShowImage(image,0,0)
            sys.exit(0)
        elif command_str.find("poweroff") > 0: 
            image = Image.open(os.path.join(whereami,"pic/bye.jpg"))
            disp.ShowImage(image,0,0)
            cmd_result=os.popen(command_str).read()
        else:
            select_index_bp=select_index
            cur_display_first_bp=cur_display_first
            select_index=0
            cur_display_first=1
            draw_info(format_str("Command: \n" + command_str))
            draw_info(format_str("Waiting..."))
            cmd_result=os.popen(command_str).read()
            logger.debug("Command:\n" + command_str + "\n" + cmd_result)
            draw_info(format_str("Result: \n" + cmd_result))
            draw_info(format_str("complete"))
            listen_kbd(all_centent,enable_ok=0)
            select_index=select_index_bp
            cur_display_first=cur_display_first_bp
            show(menu)

def listen_kbd(source_list,enable_ok=1,enable_cancel=1):
    global select_index
    while 1:
        if not GPIO.input(KEY_UP_PIN):
            select_index -= 1
            show(source_list)
            time.sleep(interval_second)
            
        if not GPIO.input(KEY_LEFT_PIN):
            select_index -= 1
            show(source_list)
            time.sleep(interval_second)
            
        if not GPIO.input(KEY_RIGHT_PIN):
            select_index += 1
            show(source_list)
            time.sleep(interval_second)
            
        if not GPIO.input(KEY_DOWN_PIN): 
            select_index += 1
            show(source_list)
            time.sleep(interval_second)
            
        if not GPIO.input(KEY_PRESS_PIN):
            print("CENTER")
            time.sleep(interval_second)
            
        if not GPIO.input(KEY1_PIN):
            if not enable_ok: continue
            logger.debug("KEY1,ok")
            show(source_list,1)
            time.sleep(interval_second)
            
        if not GPIO.input(KEY2_PIN):
            if not enable_cancel: continue
            logger.debug("KEY2,cancel")
            time.sleep(interval_second)
            break
            
        if not GPIO.input(KEY3_PIN):
            logger.debug("KEY3,reset")
            time.sleep(interval_second)

if __name__ == "__main__":
    draw_header()
    show(menu)
    listen_kbd(menu,enable_cancel=0)
