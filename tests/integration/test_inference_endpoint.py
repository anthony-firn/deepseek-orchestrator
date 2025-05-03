"""
Integration test: ping a running vLLM /deploy_model.sh endpoint.

By default, the test is skipped unless the environment variable
  VLLM_ENDPOINT_URL  (e.g. http://localhost:8000) is set in CI or locally.

You can expose the endpoint in GitHub Actions by running deploy_model.sh
in the background in a service container or self‑hosted runner.
"""
import os, json, pytest, requests

ENDPOINT = os.getenv("VLLM_ENDPOINT_URL")

pytestmark = pytest.mark.skipif(
    ENDPOINT is None,
    reason="VLLM_ENDPOINT_URL env var not set – skipping live inference test",
)

def test_basic_completion():
    url = f"{ENDPOINT.rstrip('/')}/v1/chat/completions"
    payload = {
        "model": "test-model",
        "messages": [{"role": "user", "content": "ping"}],
        "max_tokens": 8,
        "temperature": 0.0,
    }
    r = requests.post(url, json=payload, timeout=15)
    assert r.status_code == 200, f"status {r.status_code}: {r.text[:200]}"

    data = r.json()
    assert "choices" in data
    assert data["choices"][0]["message"]["content"], "empty completion"
