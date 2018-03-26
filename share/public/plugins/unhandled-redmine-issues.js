(function() {
	'use strict';

	angular.module('StatusDashboard').directive('unhandledRedmineIssues', [
		'statusService',
		function(statusService) {
			return {
				restrict:    'E',
				link :       function(scope, element, attrs) {
					scope.issues = [];

					scope.$watch(
						function() {
							return statusService.getStatus(scope.statusId)
						},
						function(newValue, oldValue) {
							if (newValue === null) {
								return;
							}
							scope.issues = newValue;
						}
					);
					scope.$watch('priorityClassStr', function (newValue, oldValue) {
						scope.priorityClass = scope.$eval(newValue);
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/unhandled-redmine-issues.html',
				scope:       {
					statusId:         '@statusId',
					statusTitle:      '@statusTitle',
					count:            '@count',
					priorityClassStr: '@priorityClass',
				}
			}
		}
	]);
}());
