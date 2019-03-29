INVITE sip:5554443333@localhost;transport=UDP SIP/2.0
Via: SIP/2.0/UDP 10.0.0.140:43017;branch=z9hG4bK-d8754z-71c87a1a39321e30-1---d8754z-
Max-Forwards: 70
Contact: <sip:smoketest@10.0.0.140:43017;transport=UDP>
To: <sip:5554443333@localhost;transport=UDP>
From: <sip:smoketest@localhost;transport=UDP>;tag=cbe80728
Call-ID: YWI1Mjk1OTBmZWEzY2EyYTg4OGFlYjQ5NzhhMWE0Y2I.
CSeq: 1 INVITE
Allow: INVITE, ACK, CANCEL, BYE, NOTIFY, REFER, MESSAGE, OPTIONS, INFO, SUBSCRIBE
Content-Type: application/sdp
Supported: replaces, norefersub, extended-refer, timer, X-cisco-serviceuri
User-Agent: Z 3.3.21937 r21903
Allow-Events: presence, kpml
Content-Length: 282

v=0
o=Z 0 0 IN IP4 10.0.0.140
s=Z
c=IN IP4 10.0.0.140
t=0 0
m=audio 8000 RTP/AVP 18 3 110 8 0 98 101
a=rtpmap:18 G729/8000
a=fmtp:18 annexb=no
a=rtpmap:110 speex/8000
a=rtpmap:98 iLBC/8000
a=fmtp:98 mode=20
a=rtpmap:101 telephone-event/8000
