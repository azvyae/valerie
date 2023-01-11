<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class DumpDatabase extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'db:dump {tables}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Dump database data based on table';

    public function handle()
    {
        $connection = env('DB_CONNECTION');
        $tables = collect(explode(',', $this->argument('tables')));
        switch ($connection) {
            case 'pgsql':
                return $this->dumpPgsql($tables);
            case 'mysql':
                return $this->dumpMysql($tables);
            case 'sqlite':
                return $this->dumpSqlite($tables);
        }
        $this->error("Database Connection of \"$connection\" is invalid");
        return Command::FAILURE;
    }

    /**
     * Dump PostgreSQL Database
     * @param \Illuminate\Support\Collection $tables
     * @return void|int
     */
    private function dumpPgsql($tables)
    {
        $tables->map(function ($table) {
            return strtolower($table);
        })->each(function ($table) {
            try {
                \Spatie\DbDumper\Databases\PostgreSql::create()
                    ->setDbName(env('DB_DATABASE'))
                    ->setUserName(env('DB_USERNAME'))
                    ->setPassword(env('DB_PASSWORD'))
                    ->includeTables([$table])
                    ->setHost(env('DB_HOST'))
                    ->addExtraOption('--rows-per-insert=1024')
                    ->doNotCreateTables()
                    ->dumpToFile(base_path("database/dump/temp-$table.sql"));
            } catch (\Spatie\DbDumper\Exceptions\DumpFailed $th) {
                return $this->removeDumpedDataIfError($table);
            }
            $this->simplifyFile($table);
            $this->info("Successfully dumped tables named: $table");
            return Command::SUCCESS;
        });

    }


    private function dumpMysql($tables)
    {
        $tables->map(function ($table) {
            return strtolower($table);
        })->each(function ($table) {
            try {
                \Spatie\DbDumper\Databases\MySql::create()
                    ->setDbName(env('DB_DATABASE'))
                    ->setUserName(env('DB_USERNAME'))
                    ->setPassword(env('DB_PASSWORD'))
                    ->includeTables([$table])
                    ->setHost(env('DB_HOST'))
                    ->addExtraOption('--complete-insert')
                    ->doNotCreateTables()
                    ->dumpToFile(base_path("database/dump/temp-$table.sql"));
            } catch (\Spatie\DbDumper\Exceptions\DumpFailed $th) {
                return $this->removeDumpedDataIfError($table);
            }
            $this->simplifyFile($table);
            $this->info("Successfully dumped tables named: $table");
            return Command::SUCCESS;
        });
        return Command::SUCCESS;

    }

    private function dumpSqlite($tables)
    {
        $tables->map(function ($table) {
            return strtolower($table);
        })->each(function ($table) {
            try {
                \Spatie\DbDumper\Databases\Sqlite::create()
                    ->setDbName(base_path("database/database.sqlite"))
                    ->doNotCreateTables()
                    ->dumpToFile(base_path("database/dump/temp-$table.sql"));
            } catch (\Spatie\DbDumper\Exceptions\DumpFailed $th) {
                return $this->removeDumpedDataIfError($table);
            }
            $this->simplifyFile($table);
            $this->info("Successfully dumped tables named $table");
            return Command::SUCCESS;
        });
        return Command::SUCCESS;
    }


    private function simplifyFile($table)
    {
        $in = fopen(base_path("database/dump/temp-$table.sql"), 'r');
        $out = fopen(base_path("database/dump/$table.sql"), 'w');
        for ($i = 0; $i < 20; $i++) {
            fgets($in);
        }
        while (($line = fgets($in)) !== false) {
            fwrite($out, $line);
        }
        fclose($in);
        fclose($out);
        unlink(base_path("database/dump/temp-$table.sql"));
    }

    private function removeDumpedDataIfError($table)
    {
        $this->error("No table named $table found");
        if ($path = base_path("database/dump/$table.sql")) {
            unlink($path);
        }
        return Command::FAILURE;
    }
}