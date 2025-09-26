import psycopg2
import pandas as pd
from sqlalchemy import create_engine
import os
from typing import Optional

class PostgreSQLConnection:
    def __init__(self, host: str, database: str, username: str, password: str, port: int = 5432):
        self.host = host
        self.database = database
        self.username = username
        self.password = password
        self.port = port
        self.connection = None
        self.engine = None
    
    def connect(self) -> bool:
        """Establish connection to PostgreSQL database"""
        try:
            self.connection = psycopg2.connect(
                host=self.host,
                database=self.database,
                user=self.username,
                password=self.password,
                port=self.port
            )
            print("✅ Successfully connected to PostgreSQL database!")
            return True
        except psycopg2.Error as e:
            print(f"❌ Error connecting to PostgreSQL: {e}")
            return False
    
    def create_sqlalchemy_engine(self):
        """Create SQLAlchemy engine for pandas integration"""
        connection_string = f"postgresql://{self.username}:{self.password}@{self.host}:{self.port}/{self.database}"
        self.engine = create_engine(connection_string)
        return self.engine
    
    def execute_query(self, query: str) -> Optional[list]:
        """Execute a SELECT query and return results"""
        if not self.connection:
            print("❌ No database connection. Call connect() first.")
            return None
        
        try:
            cursor = self.connection.cursor()
            cursor.execute(query)
            results = cursor.fetchall()
            cursor.close()
            return results
        except psycopg2.Error as e:
            print(f"❌ Error executing query: {e}")
            return None
    
    def execute_command(self, command: str) -> bool:
        """Execute INSERT, UPDATE, DELETE, or CREATE commands"""
        if not self.connection:
            print("❌ No database connection. Call connect() first.")
            return False
        
        try:
            cursor = self.connection.cursor()
            cursor.execute(command)
            self.connection.commit()
            cursor.close()
            print("✅ Command executed successfully!")
            return True
        except psycopg2.Error as e:
            print(f"❌ Error executing command: {e}")
            self.connection.rollback()
            return False
    
    def query_to_dataframe(self, query: str) -> Optional[pd.DataFrame]:
        """Execute query and return results as pandas DataFrame"""
        if not self.engine:
            self.create_sqlalchemy_engine()
        
        try:
            df = pd.read_sql_query(query, self.engine)
            return df
        except Exception as e:
            print(f"❌ Error creating DataFrame: {e}")
            return None
    
    def dataframe_to_table(self, df: pd.DataFrame, table_name: str, if_exists: str = 'replace') -> bool:
        """Write pandas DataFrame to PostgreSQL table"""
        if not self.engine:
            self.create_sqlalchemy_engine()
        
        try:
            df.to_sql(table_name, self.engine, if_exists=if_exists, index=False)
            print(f"✅ DataFrame written to table '{table_name}' successfully!")
            return True
        except Exception as e:
            print(f"❌ Error writing DataFrame to table: {e}")
            return False
    
    def close(self):
        """Close database connection"""
        if self.connection:
            self.connection.close()
            print("🔒 Database connection closed.")

# Example usage
def main():
    # Database connection parameters
    DB_CONFIG = {
        'host': 'database-1.caxoakc40kqp.us-east-1.rds.amazonaws.com',
        'database': 'postgres',  # Replace with your database name
        'username': 'postgres',  # Replace with your RDS username
        'password': 'uag123456789',  # Replace with your RDS password
        'port': 5432
    }
    
    # Alternative: Use environment variables for security
    # DB_CONFIG = {
    #     'host': 'database-1.caxoakc40kqp.us-east-1.rds.amazonaws.com',
    #     'database': os.getenv('DB_NAME', 'postgres'),
    #     'username': os.getenv('DB_USER'),
    #     'password': os.getenv('DB_PASSWORD'),
    #     'port': int(os.getenv('DB_PORT', 5432))
    # }
    
    # Create connection instance
    db = PostgreSQLConnection(**DB_CONFIG)
    
    # Connect to database
    if db.connect():
        
        # Test connection with a simple query
        print("\n📊 Testing connection...")
        result = db.execute_query("SELECT version();")
        if result:
            print(f"PostgreSQL Version: {result[0][0]}")
        
        # Example: Create a test table
        print("\n🔨 Creating test table...")
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS test_table (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100),
            email VARCHAR(100),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        db.execute_command(create_table_sql)
        
        # Example: Insert sample data
        print("\n📝 Inserting sample data...")
        insert_sql = """
        INSERT INTO test_table (name, email) 
        VALUES ('John Doe', 'john@example.com'),
               ('Jane Smith', 'jane@example.com');
        """
        db.execute_command(insert_sql)
        
        # Example: Query data using pandas
        print("\n📋 Querying data with pandas...")
        df = db.query_to_dataframe("SELECT * FROM test_table;")
        if df is not None:
            print(df)
        
        # Example: Query data traditionally
        print("\n📋 Querying data traditionally...")
        results = db.execute_query("SELECT * FROM test_table;")
        if results:
            for row in results:
                print(row)
        
        # Close connection
        db.close()

if __name__ == "__main__":
    main()