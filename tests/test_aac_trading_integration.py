from pathlib import Path
import runpy
import unittest

class TradingIntegrationTests(unittest.TestCase):
    def test_actual_market_and_money_callbacks(self):
        runpy.run_path(str(Path(__file__).with_name("trading_integration_cases.py")))
