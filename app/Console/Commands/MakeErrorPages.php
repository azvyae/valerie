<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class MakeErrorPages extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'make:error-pages';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generate static HTML error pages to public folder based on views/errors directory.';

    /**
     * Execute the console command.
     *
     * @return string
     */
    public function handle()
    {
        $path = public_path('errors');
        $error_codes = ['401', '403', '404', '419', '429', '500', '503'];
        foreach ($error_codes as $code) {
            $file_code = fopen("$path/$code.html", "w") or die("Unable to open file!");
            fwrite($file_code, view("errors.$code")->render());
            fclose($file_code);
        }
        echo "\033[1m[Artisan: Generate Error Pages]\033[0m\n";
        echo "Successfully updated static error pages to public folder\n";
        return 1;
    }
}
