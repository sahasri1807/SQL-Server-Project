# Music Streaming Database System

## Team members : Nunemuntala Sahasri (N10010782), Kelvin Idoko (N01777723) and Hassana Abdullahi (N10000326)

##  Project Overview
This project is a SQL Server-based Music Streaming Database System designed using Transact-SQL (T-SQL). It simulates a real-world music streaming platform where users can stream songs, create playlists, track listening history, and manage subscriptions.

The system is fully backend-driven with no frontend, no ORM, and no GUI tools. It focuses on relational database design, normalization, procedural logic, security, transactions, and performance optimization.

---

##  Database Features

The system includes the following core modules:

- User management with role-based access control
- Song, artist, album, and genre management
- Playlist creation and song mapping
- Listening history tracking
- Subscription management system
- Security roles and permissions
- Stored procedures, functions, views, and triggers
- Transaction handling and indexing optimization

---

##  Schema Overview

The database is normalized to **Third Normal Form (3NF)** and includes the following entities:

- Roles
- Users
- Artists
- Albums
- Songs
- Genres
- Playlists
- PlaylistSongs (junction table)
- ListeningHistory
- Subscriptions

Relationships are designed to ensure:
- Data consistency
- Referential integrity
- Elimination of redundancy

---

##  Security Implementation

- Role-based access control (Admin, User, Artist, Moderator)
- GRANT, REVOKE, DENY permissions applied
- Row-level security implemented using views
- Access restricted based on user roles

---

##  Key Functionalities

- Stored Procedures (5+ implemented)
- User Defined Functions (2+ implemented)
- Views for abstraction and reporting
- Triggers for enforcing data integrity
- Transaction management using TRY...CATCH
- Cursor-based processing
- Dynamic SQL implementation

---

##  Optimization

- Clustered and non-clustered indexes implemented
- Query execution plan analysis performed
- Performance improved using indexing strategies

