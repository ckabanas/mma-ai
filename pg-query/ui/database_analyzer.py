import psycopg2
import psycopg2.extras
from typing import List, Dict, Any, Tuple, Optional

class DatabaseAnalyzer:
    """Simplified class to analyze PostgreSQL database schema and execute queries."""

    def __init__(self, dbname: str, user: str, password: str, host: str = "localhost", port: str = "5432"):
        """Initialize with database connection parameters."""
        self.connection_params = {
            "dbname": dbname,
            "user": user,
            "password": password,
            "host": host,
            "port": port
        }
        self.connection = None
        self.schema_info = {}
        self.column_semantics = {}  # Store basic meanings of column names

    def connect(self) -> Tuple[bool, str]:
        """Establish connection to the database."""
        try:
            self.connection = psycopg2.connect(**self.connection_params)
            return True, "Connected to PostgreSQL database successfully!"
        except Exception as e:
            return False, f"Error connecting to PostgreSQL database: {e}"

    def close(self) -> str:
        """Close the database connection."""
        if self.connection:
            self.connection.close()
            return "Database connection closed."

    def get_tables(self) -> List[str]:
        """Get all table names in the database."""
        if not self.connection:
            self.connect()

        cursor = self.connection.cursor()
        cursor.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name
        """)
        tables = [row[0] for row in cursor.fetchall()]
        cursor.close()
        return tables

    def get_table_columns(self, table_name: str) -> List[Dict[str, str]]:
        """Get column details for a specific table."""
        if not self.connection:
            self.connect()

        cursor = self.connection.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cursor.execute("""
            SELECT column_name, data_type, is_nullable, column_default,
                   character_maximum_length, numeric_precision, numeric_scale
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = %s
            ORDER BY ordinal_position
        """, (table_name,))

        columns = []
        for row in cursor.fetchall():
            columns.append({
                "name": row["column_name"],
                "type": row["data_type"],
                "nullable": row["is_nullable"],
                "default": row["column_default"],
                "max_length": row["character_maximum_length"],
                "precision": row["numeric_precision"],
                "scale": row["numeric_scale"]
            })

        cursor.close()
        return columns

    def get_foreign_keys(self) -> List[Dict[str, str]]:
        """Get all foreign key relationships in the database."""
        if not self.connection:
            self.connect()

        cursor = self.connection.cursor(cursor_factory=psycopg2.extras.DictCursor)
        cursor.execute("""
            SELECT
                tc.table_name AS table_name,
                kcu.column_name AS column_name,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name
            FROM
                information_schema.table_constraints AS tc
                JOIN information_schema.key_column_usage AS kcu
                    ON tc.constraint_name = kcu.constraint_name
                JOIN information_schema.constraint_column_usage AS ccu
                    ON ccu.constraint_name = tc.constraint_name
            WHERE tc.constraint_type = 'FOREIGN KEY'
        """)

        foreign_keys = []
        for row in cursor.fetchall():
            foreign_keys.append({
                "table": row["table_name"],
                "column": row["column_name"],
                "foreign_table": row["foreign_table_name"],
                "foreign_column": row["foreign_column_name"]
            })

        cursor.close()
        return foreign_keys

    def get_primary_keys(self) -> Dict[str, List[str]]:
        """Get primary key columns for each table."""
        if not self.connection:
            self.connect()

        cursor = self.connection.cursor()
        cursor.execute("""
            SELECT
                tc.table_name,
                kcu.column_name
            FROM
                information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                    ON tc.constraint_name = kcu.constraint_name
            WHERE
                tc.constraint_type = 'PRIMARY KEY'
                AND tc.table_schema = 'public'
            ORDER BY tc.table_name, kcu.ordinal_position
        """)

        primary_keys = {}
        for table_name, column_name in cursor.fetchall():
            if table_name not in primary_keys:
                primary_keys[table_name] = []
            primary_keys[table_name].append(column_name)

        cursor.close()
        return primary_keys

    def get_comment_for_column(self, table_name: str, column_name: str) -> str:
        """Get the comment (if any) for a specific column."""
        if not self.connection:
            self.connect()

        cursor = self.connection.cursor()
        cursor.execute("""
            SELECT pg_description.description
            FROM pg_description
            JOIN pg_class ON pg_description.objoid = pg_class.oid
            JOIN pg_attribute ON pg_attribute.attrelid = pg_class.oid
                             AND pg_description.objsubid = pg_attribute.attnum
            WHERE pg_class.relname = %s AND pg_attribute.attname = %s
        """, (table_name, column_name))

        result = cursor.fetchone()
        cursor.close()

        return result[0] if result and result[0] else ""

    def get_comment_for_table(self, table_name: str) -> str:
        """Get the comment (if any) for a specific table."""
        if not self.connection:
            self.connect()

        cursor = self.connection.cursor()
        cursor.execute("""
            SELECT pg_description.description
            FROM pg_description
            JOIN pg_class ON pg_description.objoid = pg_class.oid
            WHERE pg_class.relname = %s AND pg_description.objsubid = 0
        """, (table_name,))

        result = cursor.fetchone()
        cursor.close()

        return result[0] if result and result[0] else ""

    def get_sample_data(self, table_name: str, limit: int = 3) -> List[Dict[str, Any]]:
        """Get sample data from a table."""
        if not self.connection:
            self.connect()

        cursor = self.connection.cursor(cursor_factory=psycopg2.extras.DictCursor)
        try:
            cursor.execute(f"SELECT * FROM {table_name} LIMIT {limit}")
            columns = [desc[0] for desc in cursor.description]

            results = []
            for row in cursor.fetchall():
                result_dict = {}
                for i, column in enumerate(columns):
                    result_dict[column] = row[i]
                results.append(result_dict)

            return results
        except Exception as e:
            print(f"Error getting sample data: {e}")
            return []
        finally:
            cursor.close()

    def analyze_schema(self) -> Dict[str, Any]:
        """
        Analyze the database schema using a basic approach without LLM.
        """
        tables = self.get_tables()
        foreign_keys = self.get_foreign_keys()
        primary_keys = self.get_primary_keys()

        schema_info = {
            "tables": {},
            "relationships": [],
            "primary_keys": primary_keys,
            "sample_data": {}
        }

        # Get information about each table and its columns
        for table in tables:
            columns = self.get_table_columns(table)

            # Get table comment
            table_comment = self.get_comment_for_table(table)

            # Process each column
            processed_columns = []
            for column in columns:
                # Get column comment if any
                column_comment = self.get_comment_for_column(table, column["name"])
                
                # Add comment to column info if available
                column_with_comment = column.copy()
                if column_comment:
                    column_with_comment["comment"] = column_comment

                processed_columns.append(column_with_comment)

            # Store table with its columns and comments
            schema_info["tables"][table] = {
                "columns": processed_columns,
                "comment": table_comment if table_comment else ""
            }

            # Get sample data
            sample_data = self.get_sample_data(table)
            if sample_data:
                schema_info["sample_data"][table] = sample_data

        # Add relationship information
        for fk in foreign_keys:
            schema_info["relationships"].append({
                "table": fk["table"],
                "column": fk["column"],
                "references_table": fk["foreign_table"],
                "references_column": fk["foreign_column"]
            })

        self.schema_info = schema_info
        return schema_info

    def generate_schema_description(self) -> str:
        """Generate a human-readable description of the database schema."""
        if not self.schema_info:
            self.analyze_schema()

        description = "Database Schema:\n\n"

        # Describe each table and its columns
        for table_name, table_info in self.schema_info["tables"].items():
            description += f"Table: {table_name}"

            # Add table comment if available
            if table_info.get("comment"):
                description += f" - {table_info['comment']}"
            description += "\n"

            description += "Columns:\n"

            for column in table_info["columns"]:
                nullable = "NULL" if column["nullable"] == "YES" else "NOT NULL"
                default = f", DEFAULT: {column['default']}" if column.get("default") else ""

                description += f"  - {column['name']} ({column['type']}, {nullable}{default})"

                # Add comment if available
                if "comment" in column and column["comment"]:
                    description += f" - {column['comment']}"

                description += "\n"

            # Add primary key information
            if table_name in self.schema_info.get("primary_keys", {}):
                pk_columns = self.schema_info["primary_keys"][table_name]
                description += f"  Primary Key: {', '.join(pk_columns)}\n"

            # Add sample data if available
            if table_name in self.schema_info.get("sample_data", {}):
                description += "Sample data:\n"
                for i, row in enumerate(self.schema_info["sample_data"][table_name][:2]):
                    description += f"  Row {i+1}: {row}\n"

            description += "\n"

        # Describe relationships
        if self.schema_info["relationships"]:
            description += "Relationships:\n"
            for rel in self.schema_info["relationships"]:
                description += f"  - {rel['table']}.{rel['column']} references {rel['references_table']}.{rel['references_column']}\n"

        return description

    def generate_schema_for_llm(self) -> str:
        """
        Generate a schema description for the LLM with simple format.
        """
        if not self.schema_info:
            self.analyze_schema()

        schema_text = "# Database Schema\n\n"

        # Describe each table and its columns
        for table_name, table_info in self.schema_info["tables"].items():
            schema_text += f"## Table: {table_name}"

            # Add table comment if available
            if table_info.get("comment"):
                schema_text += f" - {table_info['comment']}"
            schema_text += "\n\n"

            # Create a markdown table for column info
            schema_text += "| Column Name | Type | Description |\n"
            schema_text += "|------------|------|-------------|\n"

            for column in table_info["columns"]:
                comment = column.get("comment", "")
                schema_text += f"| {column['name']} | {column['type']} | {comment} |\n"

            schema_text += "\n"

        # Add relationships section
        if self.schema_info["relationships"]:
            schema_text += "## Relationships\n\n"

            for rel in self.schema_info["relationships"]:
                schema_text += f"- {rel['table']}.{rel['column']} → {rel['references_table']}.{rel['references_column']}\n"

            schema_text += "\n"

        return schema_text

    def execute_query(self, query: str) -> Tuple[List[Dict[str, Any]], List[str]]:
        """Execute an SQL query and return the results as a list of dictionaries."""
        if not self.connection:
            self.connect()

        # Check if the current connection is in an aborted transaction state
        # If so, rollback and reconnect to get a fresh connection
        try:
            check_cursor = self.connection.cursor()
            check_cursor.execute("SELECT 1")
            check_cursor.close()
        except psycopg2.errors.InFailedSqlTransaction:
            # Rollback the aborted transaction
            self.connection.rollback()
            print("Rolled back failed transaction")
        except Exception as e:
            # If connection is in a bad state, close and reconnect
            print(f"Connection check failed: {e}")
            try:
                self.connection.close()
            except:
                pass
            self.connect()

        cursor = self.connection.cursor(cursor_factory=psycopg2.extras.DictCursor)
        try:
            cursor.execute(query)

            # Get column names
            columns = [desc[0] for desc in cursor.description] if cursor.description else []

            # Fetch all results
            results = []
            for row in cursor.fetchall():
                result_dict = {}
                for i, column in enumerate(columns):
                    result_dict[column] = row[i]
                results.append(result_dict)

            # Explicitly commit the transaction if successful
            self.connection.commit()
            return results, columns
        except Exception as e:
            # Explicitly rollback the transaction on error
            self.connection.rollback()
            raise Exception(f"Error executing query: {e}")
        finally:
            cursor.close()

    def check_connection_health(self) -> bool:
        """
        Check if the database connection is healthy and not in a failed transaction state.
        Returns True if connection is good, False otherwise.
        """
        if not self.connection:
            return False

        try:
            check_cursor = self.connection.cursor()
            check_cursor.execute("SELECT 1")
            check_cursor.close()
            return True
        except psycopg2.errors.InFailedSqlTransaction:
            # Rollback the aborted transaction
            self.connection.rollback()
            print("Rolled back failed transaction")
            return True
        except Exception as e:
            print(f"Connection health check failed: {e}")
            return False
