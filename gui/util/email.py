import os, sys, settings
from util.decorator import async
import smtplib
from email import encoders
from email.mime.base import MIMEBase
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# for Debugging
def print_debug(e):
    print(str(e))
    exc_type, exc_obj, exc_tb = sys.exc_info()
    fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
    print(exc_type, fname, exc_tb.tb_lineno)

@async
def send_email(recipients, text_body, html_body=None, subject=settings.MAIL_DEFAULT_SUBJECT,
               sender=settings.MAIL_DEFAULT_SENDER, data=None, attachments=None):

    if not data == None:
        print("Adding data to text_body")
        text_body += "\r\n\n"
        for key, value in data.items():
            text_body += "{}: {}\n".format(key,value)
        text_body += "\n"

    print("Creating email")
    msg_root = MIMEMultipart('alternative')
    msg_root['From'] = sender
    msg_root['To'] = ", ".join(recipients)
    msg_root['Subject'] = subject
    msg_root.preamble = "|-------------------MULTIPART_BOUNDARY-------------------|\n"

    print("Adding text body to email")
    msg_root.attach(MIMEText(text_body, 'plain'))

    if not html_body == None and not html_body == "":
        print("Adding html body to email")
        msg_root.attach(MIMEText(html_body, 'html'))

    if not attachments == None:
        print("Adding attachments to email")
        for file in attachments:
            try:
                with open(file, 'rb') as fp:
                    msg_attachments = MIMEBase('application', "octet-stream")
                    msg_attachments.set_payload(fp.read())
                encoders.encode_base64(msg_attachments)
                msg_attachments.add_header('Content-Disposition', 'attachment', filename=os.path.basename(file))
                msg_root.attach(msg_attachments)
            except Exception as e:
                print_debug(e)
                raise

    # send_async_email(app, msg_root)
    try:
        print("sending email")
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.connect(settings.MAIL_SERVER, settings.MAIL_PORT)
        server.ehlo()
        server.starttls()
        server.ehlo()
        server.login(settings.MAIL_USERNAME, settings.MAIL_PASSWORD)
        msg_root_str = msg_root.as_string()
        server.sendmail(sender, recipients, msg_root_str)
        server.quit()
    except Exception as e:
        print_debug(e)
        raise
