#!/usr/bin/env python3
"""
API Test Script for Arcol Protocol
Tests all API endpoints for availability and correctness
"""

import requests
import json
import sys
import time
from typing import Dict, Any, Optional

BASE_URL = "http://127.0.0.1:8000/api/v1"
TEST_USERNAME = f"testuser_{int(time.time())}"
TEST_PASSWORD = "testpassword123"

class APITester:
    def __init__(self):
        self.token: Optional[str] = None
        self.user_id: Optional[int] = None
        self.results: Dict[str, Dict[str, Any]] = {}
    
    def log(self, name: str, success: bool, message: str = ""):
        status = "PASS" if success else "FAIL"
        print(f"[{status}] {name}")
        if message:
            print(f"       {message}")
        self.results[name] = {"success": success, "message": message}
    
    def get_headers(self) -> Dict[str, str]:
        headers = {"Content-Type": "application/json"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        return headers
    
    def test_health(self):
        try:
            r = requests.get(f"{BASE_URL.replace('/api/v1', '')}/health", timeout=5)
            self.log("GET /health", r.status_code == 200, f"Status: {r.status_code}")
        except Exception as e:
            self.log("GET /health", False, str(e))
    
    def test_register(self):
        try:
            r = requests.post(
                f"{BASE_URL}/auth/register",
                json={
                    "username": TEST_USERNAME,
                    "password": TEST_PASSWORD,
                    "email": f"{TEST_USERNAME}@test.com"
                },
                timeout=10
            )
            if r.status_code in [200, 201]:
                self.log("POST /auth/register", True, f"Status: {r.status_code}")
                self.user_id = r.json().get("id")
            else:
                self.log("POST /auth/register", False, f"Status: {r.status_code}, {r.text[:100]}")
        except Exception as e:
            self.log("POST /auth/register", False, str(e))
    
    def test_login(self):
        try:
            r = requests.post(
                f"{BASE_URL}/auth/login",
                data={"username": TEST_USERNAME, "password": TEST_PASSWORD},
                timeout=10
            )
            if r.status_code == 200:
                self.token = r.json().get("access_token")
                self.log("POST /auth/login", True, f"Status: {r.status_code}")
            else:
                self.log("POST /auth/login", False, f"Status: {r.status_code}, {r.text[:100]}")
        except Exception as e:
            self.log("POST /auth/login", False, str(e))
    
    def test_get_me(self):
        try:
            r = requests.get(f"{BASE_URL}/auth/me", headers=self.get_headers(), timeout=10)
            self.log("GET /auth/me", r.status_code == 200, f"Status: {r.status_code}")
        except Exception as e:
            self.log("GET /auth/me", False, str(e))
    
    def test_todo_crud(self):
        # Create
        try:
            r = requests.post(
                f"{BASE_URL}/todos",
                json={"title": "Test Todo", "priority": 2},
                headers=self.get_headers(),
                timeout=10
            )
            if r.status_code == 201:
                todo_id = r.json().get("id")
                self.log("POST /todos (create)", True, f"ID: {todo_id}")
                
                # Read
                r = requests.get(f"{BASE_URL}/todos", headers=self.get_headers(), timeout=10)
                self.log("GET /todos (list)", r.status_code == 200, f"Status: {r.status_code}")
                
                # Update
                r = requests.put(
                    f"{BASE_URL}/todos/{todo_id}",
                    json={"completed": True},
                    headers=self.get_headers(),
                    timeout=10
                )
                self.log("PUT /todos/:id (update)", r.status_code == 200, f"Status: {r.status_code}")
                
                # Delete
                r = requests.delete(f"{BASE_URL}/todos/{todo_id}", headers=self.get_headers(), timeout=10)
                self.log("DELETE /todos/:id", r.status_code in [200, 204], f"Status: {r.status_code}")
            else:
                self.log("POST /todos (create)", False, f"Status: {r.status_code}")
        except Exception as e:
            self.log("Todo CRUD", False, str(e))
    
    def test_time_tracking(self):
        try:
            # Create session
            r = requests.post(
                f"{BASE_URL}/time-tracking/sessions",
                json={"task_name": "Test Task"},
                headers=self.get_headers(),
                timeout=10
            )
            if r.status_code == 201:
                session_id = r.json().get("id")
                self.log("POST /time-tracking/sessions", True, f"ID: {session_id}")
                
                # Stop session
                r = requests.put(
                    f"{BASE_URL}/time-tracking/sessions/{session_id}/stop",
                    headers=self.get_headers(),
                    timeout=10
                )
                self.log("PUT /time-tracking/sessions/:id/stop", r.status_code == 200, f"Status: {r.status_code}")
            else:
                self.log("POST /time-tracking/sessions", False, f"Status: {r.status_code}")
            
            # Get stats
            r = requests.get(f"{BASE_URL}/time-tracking/stats/today", headers=self.get_headers(), timeout=10)
            self.log("GET /time-tracking/stats/today", r.status_code == 200, f"Status: {r.status_code}")
        except Exception as e:
            self.log("Time Tracking", False, str(e))
    
    def test_assets(self):
        try:
            # Create
            r = requests.post(
                f"{BASE_URL}/assets",
                json={"name": "Bitcoin", "symbol": "BTC", "quantity": 0.5, "avg_cost": 30000},
                headers=self.get_headers(),
                timeout=10
            )
            if r.status_code == 201:
                asset_id = r.json().get("id")
                self.log("POST /assets (create)", True, f"ID: {asset_id}")
                
                # List
                r = requests.get(f"{BASE_URL}/assets", headers=self.get_headers(), timeout=10)
                self.log("GET /assets (list)", r.status_code == 200, f"Status: {r.status_code}")
                
                # Delete
                r = requests.delete(f"{BASE_URL}/assets/{asset_id}", headers=self.get_headers(), timeout=10)
                self.log("DELETE /assets/:id", r.status_code in [200, 204], f"Status: {r.status_code}")
            else:
                self.log("POST /assets (create)", False, f"Status: {r.status_code}")
        except Exception as e:
            self.log("Assets", False, str(e))
    
    def test_site_routes(self):
        try:
            # Create
            r = requests.post(
                f"{BASE_URL}/site-routes",
                json={"name": "Test Site", "url": "http://localhost:3000"},
                headers=self.get_headers(),
                timeout=10
            )
            if r.status_code == 201:
                route_id = r.json().get("id")
                self.log("POST /site-routes (create)", True, f"ID: {route_id}")
                
                # List
                r = requests.get(f"{BASE_URL}/site-routes", headers=self.get_headers(), timeout=10)
                self.log("GET /site-routes (list)", r.status_code == 200, f"Status: {r.status_code}")
                
                # Delete
                r = requests.delete(f"{BASE_URL}/site-routes/{route_id}", headers=self.get_headers(), timeout=10)
                self.log("DELETE /site-routes/:id", r.status_code in [200, 204], f"Status: {r.status_code}")
            else:
                self.log("POST /site-routes (create)", False, f"Status: {r.status_code}")
        except Exception as e:
            self.log("Site Routes", False, str(e))
    
    def test_rss(self):
        try:
            # Create feed
            r = requests.post(
                f"{BASE_URL}/rss/feeds",
                json={"name": "Test Feed", "url": "https://example.com/feed.xml"},
                headers=self.get_headers(),
                timeout=10
            )
            if r.status_code == 201:
                feed_id = r.json().get("id")
                self.log("POST /rss/feeds (create)", True, f"ID: {feed_id}")
                
                # List feeds
                r = requests.get(f"{BASE_URL}/rss/feeds", headers=self.get_headers(), timeout=10)
                self.log("GET /rss/feeds (list)", r.status_code == 200, f"Status: {r.status_code}")
                
                # Delete
                r = requests.delete(f"{BASE_URL}/rss/feeds/{feed_id}", headers=self.get_headers(), timeout=10)
                self.log("DELETE /rss/feeds/:id", r.status_code in [200, 204], f"Status: {r.status_code}")
            else:
                self.log("POST /rss/feeds (create)", False, f"Status: {r.status_code}")
        except Exception as e:
            self.log("RSS", False, str(e))
    
    def test_monitor(self):
        try:
            # Get metrics (no auth required)
            r = requests.get(f"{BASE_URL}/monitor/metrics", timeout=10)
            self.log("GET /monitor/metrics", r.status_code == 200, f"Status: {r.status_code}")
            
            # Create threshold
            r = requests.post(
                f"{BASE_URL}/monitor/thresholds",
                json={"metric_name": "cpu", "threshold_value": 80, "comparison": "gt"},
                headers=self.get_headers(),
                timeout=10
            )
            if r.status_code == 201:
                threshold_id = r.json().get("id")
                self.log("POST /monitor/thresholds (create)", True, f"ID: {threshold_id}")
                
                # Delete
                r = requests.delete(f"{BASE_URL}/monitor/thresholds/{threshold_id}", headers=self.get_headers(), timeout=10)
                self.log("DELETE /monitor/thresholds/:id", r.status_code in [200, 204], f"Status: {r.status_code}")
            else:
                self.log("POST /monitor/thresholds (create)", False, f"Status: {r.status_code}")
        except Exception as e:
            self.log("Monitor", False, str(e))
    
    def test_settings(self):
        try:
            # Create API key
            r = requests.post(
                f"{BASE_URL}/settings/api-keys",
                json={"name": "Test Key", "provider": "OpenAI"},
                headers=self.get_headers(),
                timeout=10
            )
            if r.status_code == 201:
                key_id = r.json().get("id")
                self.log("POST /settings/api-keys (create)", True, f"ID: {key_id}")
                
                # List
                r = requests.get(f"{BASE_URL}/settings/api-keys", headers=self.get_headers(), timeout=10)
                self.log("GET /settings/api-keys (list)", r.status_code == 200, f"Status: {r.status_code}")
                
                # Delete
                r = requests.delete(f"{BASE_URL}/settings/api-keys/{key_id}", headers=self.get_headers(), timeout=10)
                self.log("DELETE /settings/api-keys/:id", r.status_code in [200, 204], f"Status: {r.status_code}")
            else:
                self.log("POST /settings/api-keys (create)", False, f"Status: {r.status_code}")
            
            # Queue configs
            r = requests.get(f"{BASE_URL}/settings/queue-configs", headers=self.get_headers(), timeout=10)
            self.log("GET /settings/queue-configs (list)", r.status_code == 200, f"Status: {r.status_code}")
        except Exception as e:
            self.log("Settings", False, str(e))
    
    def run_all_tests(self):
        print("=" * 60)
        print("Arcol Protocol API Test Suite")
        print("=" * 60)
        print()
        
        # Public endpoints
        print("--- Public Endpoints ---")
        self.test_health()
        print()
        
        # Auth
        print("--- Authentication ---")
        self.test_register()
        self.test_login()
        if not self.token:
            print("WARNING: No token obtained, skipping authenticated tests")
            return
        self.test_get_me()
        print()
        
        # Core modules
        print("--- Todo Module ---")
        self.test_todo_crud()
        print()
        
        print("--- Time Tracking Module ---")
        self.test_time_tracking()
        print()
        
        print("--- Assets Module ---")
        self.test_assets()
        print()
        
        print("--- Site Routes Module ---")
        self.test_site_routes()
        print()
        
        print("--- RSS Module ---")
        self.test_rss()
        print()
        
        print("--- Monitor Module ---")
        self.test_monitor()
        print()
        
        print("--- Settings Module ---")
        self.test_settings()
        print()
        
        # Summary
        print("=" * 60)
        print("Summary")
        print("=" * 60)
        passed = sum(1 for r in self.results.values() if r["success"])
        total = len(self.results)
        print(f"Passed: {passed}/{total}")
        if passed == total:
            print("All tests passed!")
            return 0
        else:
            print("Some tests failed!")
            return 1


if __name__ == "__main__":
    tester = APITester()
    sys.exit(tester.run_all_tests())
