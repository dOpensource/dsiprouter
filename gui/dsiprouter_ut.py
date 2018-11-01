import unittest
from modules.domain.domain_service import *

class TestUnit(unittest.TestCase):

    def setUp(self):
        pass
    
    def test_add_static_domain(self):
        self.assertTrue(addDomain('xyc.com'))

    def test_getDomains(self):
        res = getDomains()
        assert res is not None 

if __name__ == '__main__':
    unittest.main()
