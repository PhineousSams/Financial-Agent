defmodule FinincialTool.Repo.Migrations.CreateAiFinancialAdvisorTablesWithoutVector do
  use Ecto.Migration

  def up do
    # OAuth tokens table for storing Google and HubSpot tokens
    create table(:oauth_tokens) do
      add :user_id, references(:tbl_user, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :access_token, :text, null: false
      add :refresh_token, :text
      add :expires_at, :utc_datetime
      add :scope, :text
      add :token_type, :string, default: "Bearer"

      timestamps()
    end

    create index(:oauth_tokens, [:user_id])
    create unique_index(:oauth_tokens, [:user_id, :provider])

    # Conversations table for chat sessions
    create table(:conversations) do
      add :user_id, references(:tbl_user, on_delete: :delete_all), null: false
      add :title, :string
      add :status, :string, default: "active"
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:conversations, [:user_id])
    create index(:conversations, [:status])

    # Messages table for chat messages
    create table(:messages) do
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :role, :string, null: false # "user", "assistant", "system"
      add :content, :text, null: false
      add :metadata, :map, default: %{}
      add :tokens_used, :integer
      add :function_calls, :map

      timestamps()
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:role])

    # Documents table for storing email and CRM data
    create table(:documents) do
      add :user_id, references(:tbl_user, on_delete: :delete_all), null: false
      add :source, :string, null: false # "gmail", "hubspot", "calendar"
      add :source_id, :string, null: false # external ID from the source
      add :document_type, :string, null: false # "email", "contact", "event", "note"
      add :title, :string
      add :content, :text
      add :metadata, :map, default: %{}
      add :processed_at, :utc_datetime
      add :last_synced_at, :utc_datetime

      timestamps()
    end

    create index(:documents, [:user_id])
    create index(:documents, [:source])
    create index(:documents, [:document_type])
    create unique_index(:documents, [:user_id, :source, :source_id])

    # Embeddings table for RAG (without vector type initially)
    create table(:embeddings) do
      add :document_id, references(:documents, on_delete: :delete_all), null: false
      add :content_chunk, :text, null: false
      add :embedding, :text, null: false # Store as JSON text initially
      add :chunk_index, :integer, default: 0
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:embeddings, [:document_id])

    # Tasks table for tracking AI tasks and workflows
    create table(:tasks) do
      add :user_id, references(:tbl_user, on_delete: :delete_all), null: false
      add :conversation_id, references(:conversations, on_delete: :nilify_all)
      add :title, :string, null: false
      add :description, :text
      add :status, :string, default: "pending" # "pending", "in_progress", "completed", "failed", "cancelled"
      add :task_type, :string, null: false # "email", "calendar", "hubspot", "general"
      add :context, :map, default: %{}
      add :result, :map
      add :error_message, :text
      add :scheduled_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :retry_count, :integer, default: 0
      add :max_retries, :integer, default: 3

      timestamps()
    end

    create index(:tasks, [:user_id])
    create index(:tasks, [:status])
    create index(:tasks, [:task_type])
    create index(:tasks, [:scheduled_at])

    # Ongoing instructions table for persistent AI behaviors
    create table(:ongoing_instructions) do
      add :user_id, references(:tbl_user, on_delete: :delete_all), null: false
      add :instruction, :text, null: false
      add :trigger_conditions, :map, default: %{}
      add :actions, :map, default: %{}
      add :active, :boolean, default: true
      add :priority, :integer, default: 0
      add :execution_count, :integer, default: 0
      add :last_executed_at, :utc_datetime

      timestamps()
    end

    create index(:ongoing_instructions, [:user_id])
    create index(:ongoing_instructions, [:active])
    create index(:ongoing_instructions, [:priority])

    # Gmail messages table for caching email data
    create table(:gmail_messages) do
      add :user_id, references(:tbl_user, on_delete: :delete_all), null: false
      add :message_id, :string, null: false
      add :thread_id, :string
      add :subject, :string
      add :sender, :string
      add :recipient, :string
      add :content, :text
      add :snippet, :text
      add :labels, {:array, :string}, default: []
      add :received_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:gmail_messages, [:user_id])
    create unique_index(:gmail_messages, [:user_id, :message_id])
    create index(:gmail_messages, [:thread_id])
    create index(:gmail_messages, [:received_at])

    # Calendar events table for caching calendar data
    create table(:calendar_events) do
      add :user_id, references(:tbl_user, on_delete: :delete_all), null: false
      add :event_id, :string, null: false
      add :calendar_id, :string
      add :summary, :string
      add :description, :text
      add :location, :string
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime
      add :attendees, :map, default: %{}
      add :status, :string
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:calendar_events, [:user_id])
    create unique_index(:calendar_events, [:user_id, :event_id])
    create index(:calendar_events, [:start_time])
    create index(:calendar_events, [:end_time])

    # HubSpot contacts table for caching CRM data
    create table(:hubspot_contacts) do
      add :user_id, references(:tbl_user, on_delete: :delete_all), null: false
      add :contact_id, :string, null: false
      add :email, :string
      add :first_name, :string
      add :last_name, :string
      add :company, :string
      add :phone, :string
      add :properties, :map, default: %{}
      add :last_activity_date, :utc_datetime
      add :lifecycle_stage, :string
      add :lead_status, :string

      timestamps()
    end

    create index(:hubspot_contacts, [:user_id])
    create unique_index(:hubspot_contacts, [:user_id, :contact_id])
    create index(:hubspot_contacts, [:email])
    create index(:hubspot_contacts, [:last_activity_date])

    # HubSpot deals table
    create table(:hubspot_deals) do
      add :user_id, references(:tbl_user, on_delete: :delete_all), null: false
      add :deal_id, :string, null: false
      add :deal_name, :string
      add :amount, :decimal
      add :stage, :string
      add :pipeline, :string
      add :close_date, :date
      add :associated_contacts, {:array, :string}, default: []
      add :properties, :map, default: %{}

      timestamps()
    end

    create index(:hubspot_deals, [:user_id])
    create unique_index(:hubspot_deals, [:user_id, :deal_id])
    create index(:hubspot_deals, [:stage])
    create index(:hubspot_deals, [:close_date])

    # Add Oban jobs table
    Oban.Migration.up(version: 11)
  end

  def down do
    Oban.Migration.down(version: 11)

    drop table(:hubspot_deals)
    drop table(:hubspot_contacts)
    drop table(:calendar_events)
    drop table(:gmail_messages)
    drop table(:ongoing_instructions)
    drop table(:tasks)
    drop table(:embeddings)
    drop table(:documents)
    drop table(:messages)
    drop table(:conversations)
    drop table(:oauth_tokens)
  end
end
