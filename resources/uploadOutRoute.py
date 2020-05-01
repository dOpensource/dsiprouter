import requests

# set per your own configs (get prefixs from gui/util/conversions.py)
processed_prefixs = [
'011',
]
name = 'Test Calling'
gwlist = '#9'

# set per your own configs
host = "10.10.10.154"
username = 'admin'
password = 'admin'

# auth for session cookie
URL = 'http://{}:5000/login'.format(host)
payload = {
    'username': username,
    'password': password,
    'nextpage': ''
}
headers = {
    'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
    'Accept-Encoding':'gzip, deflate',
    'Accept-Language':'en-US,en;q=0.9',
    'Cache-Control':'max-age=0',
    'Connection':'keep-alive',
    'Content-Type':'application/x-www-form-urlencoded',
    'DNT':'1',
    'Host':'{}:5000'.format(host),
    'Origin':'http://{}:5000'.format(host),
    'Referer':'http://{}:5000/'.format(host),
    'Upgrade-Insecure-Requests':'1',
    'User-Agent':'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36'
}

r1 = requests.post(URL, data=payload, headers=headers)
print("LOGIN: {}\n".format(r1.status_code))


# add outbound routes
URL = 'http://{}:5000/outboundroutes'.format(host)
payloads = [{
    'ruleid': '',
    'from_prefix': '',
    'timerec': '',
    'priority': '',
    'prefix': prefix,
    'name': name,
    'gwlist': gwlist
} for prefix in processed_prefixs]
headers = {
    'Host':'{}:5000'.format(host),
    'Connection':'keep-alive',
    'Cache-Control':'max-age=0',
    'Origin':'http://{}:5000'.format(host),
    'Upgrade-Insecure-Requests':'1',
    'DNT':'1',
    'Content-Type':'application/x-www-form-urlencoded',
    'User-Agent':'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36',
    'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
    'Referer':'http://{}:5000/outboundroutes'.format(host),
    'Accept-Encoding':'gzip, deflate',
    'Accept-Language':'en-US,en;q=0.9'
}

for payload in payloads:
    r = requests.post(URL, data=payload, headers=headers, cookies=r1.cookies)
    print("OUTBOUNDROUTES: {}".format(r.status_code))

exit(0)
