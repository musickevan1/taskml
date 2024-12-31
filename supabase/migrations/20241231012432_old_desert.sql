/*
  # Add task categories and comments

  1. New Tables
    - `task_categories`
      - `id` (uuid, primary key)
      - `name` (text)
      - `color` (text)
      - `created_by` (uuid, references users)
      - `created_at` (timestamp)
    
    - `task_category_assignments`
      - `task_id` (uuid, references tasks)
      - `category_id` (uuid, references task_categories)
    
    - `task_comments`
      - `id` (uuid, primary key)
      - `task_id` (uuid, references tasks)
      - `user_id` (uuid, references users)
      - `content` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on all new tables
    - Add policies for authenticated users
*/

-- Task Categories
CREATE TABLE task_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  color text NOT NULL,
  created_by uuid REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE task_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all categories"
  ON task_categories FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create categories"
  ON task_categories FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

-- Task Category Assignments
CREATE TABLE task_category_assignments (
  task_id uuid REFERENCES tasks(id) ON DELETE CASCADE,
  category_id uuid REFERENCES task_categories(id) ON DELETE CASCADE,
  PRIMARY KEY (task_id, category_id)
);

ALTER TABLE task_category_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all category assignments"
  ON task_category_assignments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can manage category assignments"
  ON task_category_assignments FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tasks
      WHERE tasks.id = task_id
      AND (tasks.created_by = auth.uid() OR tasks.assigned_to = auth.uid())
    )
  );

-- Task Comments
CREATE TABLE task_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid REFERENCES tasks(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read comments on accessible tasks"
  ON task_comments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tasks
      WHERE tasks.id = task_id
      AND (tasks.created_by = auth.uid() OR tasks.assigned_to = auth.uid())
    )
  );

CREATE POLICY "Users can create comments"
  ON task_comments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments"
  ON task_comments FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);