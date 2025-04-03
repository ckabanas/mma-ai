import json
import httpx
import asyncio
from typing import List, Dict, Any

class LlamaInterface:
    """Minimal interface for LLM Runtime API."""

    def __init__(self, host="llama-service", port="8080"):
        """Initialize the LLM Runtime interface with host and port."""
        self.host = host
        self.port = port

    async def get_llama_response_async(self, prompt):
        """Get a response from the LLM Runtime API asynchronously."""
        json_data = {
            'prompt': prompt,
            'temperature': 0.1,
            'repetition_penalty': 1.18,
            'n_predict': 500,
            'stream': True,
        }

        async with httpx.AsyncClient(timeout=120) as client:
            async with client.stream('POST', f'http://{self.host}:{self.port}/completion', json=json_data) as response:
                full_response = ""
                async for chunk in response.aiter_bytes():
                    try:
                        data = json.loads(chunk.decode('utf-8')[6:])
                        if data['stop'] is False:
                            full_response += data['content']
                    except:
                        pass

        return full_response

    def get_llama_response(self, prompt):
        """Synchronous wrapper for get_llama_response_async."""
        return asyncio.run(self.get_llama_response_async(prompt))

    async def explain_results_async(self, question: str, sql_query: str, results: List[Dict[str, Any]], error: str = None) -> str:
        """Explain the results in natural language."""
        if error:
            prompt = f"""
Question: {question}

SQL Query: {sql_query}

Error: {error}

Please explain what went wrong with this query in simple terms and suggest how to fix it.
Be specific about any syntax errors or invalid references.
"""
        else:
            # Convert results to a string - limit to 10 results to manage context length
            results_str = json.dumps(results[:10], indent=2, default=str)

            prompt = f"""
Question: {question}

SQL Query: {sql_query}

Results: {results_str}

Provide a natural language explanation of these results that directly answers the original question.
Keep your explanation clear, concise, and focused on what the user actually asked.
If the results contain a lot of data, summarize the key points.
"""

        explanation = await self.get_llama_response_async(prompt)
        return explanation.strip()

    def explain_results(self, question: str, sql_query: str, results: List[Dict[str, Any]], error: str = None) -> str:
        """Synchronous wrapper for explain_results_async."""
        return asyncio.run(self.explain_results_async(question, sql_query, results, error))
