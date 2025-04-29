-- Table Exercise (stockage des exercices)
create table exercise (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  primary_muscle text not null
);

-- Table WorkoutSession
create table workoutsession (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade,
  title text,
  date date not null,
  notes text,
  created_at timestamp default now(),
  updated_at timestamp default now()
);

-- Mise à jour automatique du champ updated_at pour WorkoutSession
create or replace function update_workout_session_updated_at()
  returns trigger as
$$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_workout_session_updated_at_trigger
  before update on WorkoutSession
  for each row execute function update_workout_session_updated_at();

-- Table WorkoutExercise (référence à Exercise par exercise_id)
create table workoutexercise (
  id uuid default gen_random_uuid() primary key,
  session_id uuid references WorkoutSession(id) on delete cascade,
  exercise_id uuid references Exercise(id) on delete cascade,
  "order" int not null default 0,
  created_at timestamp default now(),
  updated_at timestamp default now()
);

-- Mise à jour automatique du champ updated_at pour WorkoutExercise
create or replace function update_workout_exercise_updated_at()
  returns trigger as
$$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_workout_exercise_updated_at_trigger
  before update on WorkoutExercise
  for each row execute function update_workout_exercise_updated_at();

-- Table ExerciseSet (sets réalisés par l'utilisateur sur un exercice)
create table exerciseset (
  id uuid default gen_random_uuid() primary key,
  exercise_id uuid references Exercise(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  weight_kg float not null,
  reps int not null,
  rest_seconds int not null,
  rpe float,
  note text,
  created_at timestamp default now()
);

-- Index pour optimiser les requêtes sur ExerciseSet
create index idx_exercise_set_user_exercise on ExerciseSet(exercise_id, user_id);

-- Table PerformedSession (sessions réellement effectuées par les utilisateurs)
create table PerformedSession (
  id uuid default gen_random_uuid() primary key,
  workout_session_id uuid references WorkoutSession(id) on delete set null,
  user_id uuid references auth.users(id) on delete cascade,
  started_at timestamp not null default now(),
  ended_at timestamp,
  notes text,
  created_at timestamp default now()
);

-- Insertion des exercices avec muscles associés
insert into Exercise (id, name, primary_muscle) values
  ('b866e7c3-db9d-464f-8570-83c67faa7728', 'Squat', 'Jambes'),
  ('6d72c5ae-1df0-4b04-b931-f508b47c2a49', 'Leg press', 'Jambes'),
  ('b21f61e1-8b47-4308-a4b7-1fea09bc4b56', 'Fente avant', 'Jambes'),
  ('686d35c7-49ee-4d15-a387-29a4996eb29a', 'Soulevé de terre jambes tendues', 'Jambes'),
  ('2eca9475-7108-47cf-977e-fcd2ac0265f9', 'Extension de jambes', 'Jambes'),
  ('4c97cc8a-d191-4cc0-8b73-7b61a1e8f25a', 'Curl des ischio-jambiers', 'Jambes'),
  ('a93ff20b-cb62-4f94-b0b4-2fbd7a0bb4a7', 'Presse à cuisses', 'Jambes'),
  ('39e9c91b-6060-48e6-b6b7-df9055a07d73', 'Step-ups', 'Jambes'),
  ('f10ff1a3-d506-4b4b-b12f-bc7ac3a29988', 'Hack squat', 'Jambes'),
  ('e83f33f3-2ab3-45f0-b0bb-df9577d423ed', 'Squat bulgare', 'Jambes'),
  ('a63f0b74-5e53-4c25-b489-48cf42156d1b', 'Tractions', 'Dos'),
  ('da8e3064-f1c9-4567-b72f-d497af0b33fc', 'Rowing barre', 'Dos'),
  ('cde8c6bc-5008-4b06-a47d-bc86a682da67', 'Rowing haltères', 'Dos'),
  ('983ab15a-ffdf-4f02-bab4-3dbb933ef928', 'Tirage horizontal', 'Dos'),
  ('d6fd6f68-4a99-4301-9ae2-bc33ad973960', 'Soulevé de terre classique', 'Dos'),
  ('1d54063f-8ca7-4f8e-9469-9a911f857682', 'Soulevé de terre sumo', 'Dos'),
  ('2342f8ea-651f-4d65-bc4a-f6a4e85c0d8c', 'Deadlift avec trap bar', 'Dos'),
  ('7fc97b3c-4b6e-4640-b28c-f9f77a8bfa96', 'Rowing inversé', 'Dos'),
  ('a2f3f503-89c2-4001-9356-2db41048b940', 'Tirage vertical (lat pulldown)', 'Dos'),
  ('be2f5f62-036b-4d7c-b462-fb51e5480401', 'Hyperextensions lombaires', 'Dos'),
  ('f4e94b5e-9ff9-47fc-8d4b-8265c2781110', 'Développé couché', 'Pectoraux'),
  ('d52b56a4-f4c1-42ae-9ab6-f8c9cfc0b372', 'Développé incliné avec barre', 'Pectoraux'),
  ('2adf24cf-c763-40b2-b9f4-55114b5369ff', 'Développé incliné avec haltères', 'Pectoraux'),
  ('de963c9a-7389-4f76-90bc-f72fd4ab85f7', 'Écarté couché avec haltères', 'Pectoraux'),
  ('8f175b90-30b0-4c2f-b05d-0a7a7483d28e', 'Pompes', 'Pectoraux'),
  ('d57450ab-85b0-47c6-8c8f-c946fc88f17f', 'Développé à la machine', 'Pectoraux'),
  ('072eb574-5c59-468e-b7e6-d0bb8a3e7f35', 'Pull-over avec haltères', 'Pectoraux'),
  ('0290a58a-0ba9-465f-b35a-c174315d906b', 'Dips pour la poitrine', 'Pectoraux'),
  ('3517c0fa-df79-49a1-b559-6c0189b70e91', 'Pec deck', 'Pectoraux'),
  ('093aa1c7-33e2-497f-a514-218b73f1a682', 'Développé décliné', 'Pectoraux'),
  ('1a5cfe6d-202f-4b79-8f8b-b58eead2d89f', 'Développé militaire', 'Épaules'),
  ('88feaf2b-d22f-4670-bf0e-e1c35468bdf8', 'Élévations latérales avec haltères', 'Épaules'),
  ('c19b5d7a-dde1-426d-885b-e643e28e5d34', 'Élévations frontales', 'Épaules'),
  ('83394e47-d3cc-466e-b883-2e17b51727de', 'Arnold press', 'Épaules'),
  ('a7b0b078-d2d2-47db-9d1c-dff2355e72fd', 'Oiseau (reverse fly)', 'Épaules'),
  ('42182a28-cb71-42db-b3f2-3fa97b157423', 'Shrugs avec haltères', 'Épaules'),
  ('510cfe5e-c86e-4b3b-bbe2-e5f6e1fa9e0a', 'Développé Arnold', 'Épaules'),
  ('6d02d258-b429-42d9-83fc-1f6c7ec9cc9b', 'Élévations postérieures à la machine', 'Épaules'),
  ('44f5d0d2-e45b-4187-a6d2-32e4d709ed49', 'Face pulls', 'Épaules'),
  ('627f98de-f387-46a1-b346-01c2fe76b592', 'Développé à la machine', 'Épaules'),
  ('be43f35c-f14e-4065-a1e9-1a6021e93ed9', 'Curl biceps avec barre', 'Biceps'),
  ('e5f1a9a4-897d-4e2b-b2ac-b35a7b81f35f', 'Curl biceps avec haltères', 'Biceps'),
  ('8d2a6169-b840-4858-98f4-567a62b2da85', 'Curl marteau', 'Biceps'),
  ('2795b5db-98f7-4ad5-8bfc-c6c5b7f7d616', 'Curl concentration', 'Biceps'),
  ('2714531d-7b83-4699-9362-44b8725cb98c', 'Triceps dips', 'Triceps'),
  ('928d178f-8b1d-46f3-b9be-477a70c92b8a', 'Extension triceps à la poulie', 'Triceps'),
  ('8f53b460-7246-4cc4-9f6e-8572dc1d4518', 'Extension triceps avec haltère', 'Triceps');
