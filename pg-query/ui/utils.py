import re
from typing import List, Dict, Any, Optional

def extract_sql_from_response(response: str) -> str:
    """
    Extract SQL query from the LLM response, focusing strictly on the content inside triple backticks.
    If triple backticks are present, extract ONLY the content within them.
    If no triple backticks are found, return an empty string to avoid executing potentially unsafe queries.
    """
    # Look specifically for SQL code blocks with triple backticks
    # The pattern matches ```sql ... ``` or just ``` ... ```
    sql_block_pattern = r'```(?:sql)?(.*?)```'
    matches = re.findall(sql_block_pattern, response, re.DOTALL)

    if matches and len(matches) > 0:
        # Use the first code block found
        sql_query = matches[0].strip()
        return sql_query
    else:
        # Safer to return empty string if no triple backtick block is found
        return ""
