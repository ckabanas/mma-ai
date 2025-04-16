import re
from typing import List, Dict, Any, Optional

import re
from typing import List, Dict, Any, Optional

def extract_sql_from_response(response: str) -> str:
    """
    Extract SQL query from the LLM response, handling various edge cases:
    - Regular code blocks with ```sql ... ```
    - Nested or malformed blocks with duplicated backticks
    - Multiple sets of backticks (```sql ``` ```sql ...)
    - Code blocks without explicit sql tag

    Returns the clean SQL query or an empty string if no valid SQL code block is found.
    """
    # First, remove all occurrences of "```sql" or "```" at the beginning
    # This handles messy cases like ```sql ``` ```sql ...
    cleaned_response = re.sub(r'```(?:sql)?\s*```(?:\s*```(?:sql)?)?', '```', response)

    # Now extract content from the cleaned response
    sql_block_pattern = r'```(?:sql)?(.*?)```'
    matches = re.findall(sql_block_pattern, cleaned_response, re.DOTALL)

    if not matches:
        # No code blocks found at all
        return ""

    # Take the first code block found
    sql_query = matches[0].strip()

    # Final clean-up: remove any leading "sql" if it appears at the beginning
    sql_query = re.sub(r'^sql\s+', '', sql_query)

    return sql_query
