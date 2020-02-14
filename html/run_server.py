from flask import Flask,render_template
app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/os_install')
def os_install():
    return render_template('os_install.html')

@app.route('/display_button')
def display_button():
    return render_template('display_button.html')

@app.route('/usb_ether')
def usb_ether():
    return render_template('usb_ether.html')

@app.route('/badUSB')
def badUSB():
    return render_template('badUSB.html')

@app.route('/wireless_AP')
def wireless_AP():
    return render_template('wireless_AP.html')

@app.route('/web')
def web():
    return render_template('web.html')
